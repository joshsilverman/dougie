/* class declarations */

var cDoc = Class.create({

    outline: null,
    rightRail: null,
    editor: null,
    utilities: null,

    initialize: function() {

        //wait for ckeditor to load
        document.observe('CKEDITOR:ready', function() {

            /* member objects */
            this.utilities = new cUtilities();
            this.editor = CKEDITOR.instances.editor;
            this.rightRail = new cRightRail();

            //@todo this creates race condition - look for callback - ugglie!!!
            (function () {

                /* load outline obj */
                this.outline = new cOutline();

                /* fire editor loaded */
                document.fire('editor:loaded');
                }.bind(this)).delay(.1);

                /* resize listener */
                window.onresize = this.onResize;
                this.onResize();

        }.bind(this));

        /* select all in doc name on click */
        $('document_name').observe('click', function(e) {e.target.select();});
    },

    onResize: function() {

        /* calculations */
        var bottomMargin = 20;
        var editorContainer = $('editor_container');
        var editorContainerHeight = parseInt(editorContainer.getStyle('height'));
        var editorVerticalSpaceHeight = document.viewport.getDimensions()['height']
            - editorContainer.cumulativeOffset().top - bottomMargin;
        var editorWhitespace = $('cke_contents_editor');

        /* set minimums */
        if (editorVerticalSpaceHeight < 200) editorVerticalSpaceHeight = 200;

        /* set heights */
        editorWhitespace.setStyle({height: editorVerticalSpaceHeight - 49 + 'px'});
        $('right_rail').setStyle({height: editorVerticalSpaceHeight - 2 + 'px'});
        $('cke_editor').setStyle({height: editorVerticalSpaceHeight - 2 + 'px'});
//        $('right_rail').setStyle({height: editorVerticalSpaceHeight + 'px !important'});


    }
});

var cOutline = Class.create({

    iDoc: null,
    outlineHandlers: null,

    documentId: null,

    maxIdle: 4,
    idleSaveTimerId: null,
    maxActive: 12,
    activeSaveTimerId: null,

    unsavedChanges: [],  //list of domIds for unsaved changes
    savingChanges: [],  //list of domIds for changes sent to server (request in progress)

    deleteNodes: [],  //list of domIds for nodes to be delete
    deletingNodes: [],  //list of domIds for nodes currently being deleted (request in progress)

    initialize: function() {

        /* document members */
        this.documentId = $('document_id').innerHTML;

        /* iframe doc */
        var iframe = $$('#cke_contents_editor iframe')[0];
        this.iDoc = iframe.contentWindow || iframe.contentDocument;

        this.outlineHandlers = new cOutlineHandlers(this.iDoc);

        /* click observers */

        //save button
        Event.observe($("save_button"),"click",function(e){this.save(e);}.bind(this));

        /* outline title observer */
        $("document_name").observe('keypress', this.autosave.bind(this));
    },

    autosave: function() {
        
        /* idle save timer */
        window.clearTimeout(this.idleSaveTimerId);
        this.idleSaveTimerId = this.save.bind(this).delay(this.maxIdle);

        /* idle save timer */
        if (this.activeSaveTimerId == null)
            this.activeSaveTimerId = this.save.bind(this).delay(this.maxActive);

        /* save button styling */
        $('save_button').innerHTML = 'Save';
    },

    save: function() {

        /* cancel other timers */
        window.clearTimeout(this.idleSaveTimerId);
        window.clearTimeout(this.activeSaveTimerId);
        this.idleSaveTimerId = null;
        this.activeSaveTimerId = null;

        /* don't save if nothing changed */
        if (this.unsavedChanges.length == 0) return;

        /* sync */
        //@todo this may become unnecessary later on
        doc.rightRail.sync();

        /* save button styling */
        var saveButton = $('save_button');
        saveButton.disabled = true;
        saveButton.innerHTML = 'Saving';

        /* save */
        new Ajax.Request('/documents/update', {
            method: 'post',
            parameters: {'html': this.iDoc.document.getElementsByTagName('body')[0].innerHTML,
                         'id': this.documentId,
                         'name': $('document_name').value,
                         'delete_nodes': this.deleteNodes.toString()},

            onCreate: function() {

                /* track saving changes */
                this.unsavedChanges.each(function(domId) {
                    if (this.iDoc.document.getElementById(domId))
                        Element.writeAttribute(this.iDoc.document.getElementById(domId), {'changed': '0'});
                }.bind(this));
                this.savingChanges = this.unsavedChanges;
                this.unsavedChanges = [];

                /* track nodes being delete, clear nodes to be deleted */
                this.deletingNodes = this.deleteNodes;
                this.deleteNodes = [];
            }.bind(this),

            onSuccess: function(transport) {
                var lineIds = transport.responseText.evalJSON();
                this.updateIds(lineIds);

                /*  */
            }.bind(this),

            onFailure: function() {

                /* add unsuccessfully saved changes back to unsaved changes and set attributes */
                this.unsavedChanges = this.unsavedChanges.concat(this.savingChanges).uniq();
                this.unsavedChanges.each(function(domId) {
                    if (this.iDoc.document.getElementById(domId))
                        Element.writeAttribute(this.iDoc.document.getElementById(domId), {'changed': '1'});
                }.bind(this));

                /* add unsuccessfully deleted back to deleteNodes */
                this.deleteNodes = this.deleteNodes.concat(this.deletingNodes);
            }.bind(this),

            onComplete: function() {

                /* save button styling */
                saveButton.disabled = false;
                saveButton.innerHTML = 'Saved';

                /* clear saving changes */
                this.savingChanges = []
                this.deletingNodes = []
            }.bind(this)
        });

        /* activate card */
        document.observe('click', function(event) {
           if(event.target.hasClassName('card_activation')) this.activateNode(event.target);
        }.bind(this));

    },

    activateNode: function(checkbox) {

        //vars
        var card = checkbox.up('.card');
        var nodeId = doc.utilities.toNodeId(card);
        var node = this.iDoc.document.getElementById(nodeId);

        //activate/dactivate card
        if (checkbox.checked) {
            node.setAttribute('active', true);
            doc.rightRail.cards.get(nodeId).activate();
        }
        else {
            node.setAttribute('active', false);
            doc.rightRail.cards.get(nodeId).deactivate();
        }
    },

    updateIds: function(lineIds) {
        $H(lineIds).each(function(idArray) {
            
            /* add id */
            if (this.iDoc.document.getElementById(idArray[0]))
                this.iDoc.document.getElementById(idArray[0]).setAttribute('line_id', idArray[1]);
            
            /* remove line if no node has the associated node id */
            else {
                this.deleteNodes.push(idArray[1]);
                console.log('deleting ' + idArray[0]);
            }
        }.bind(this));
    }
});

var cOutlineHandlers = Class.create({

    iDoc: null, //@todo repeated unfortunately - can't access in outline until initialization complete

    initialize: function(iDoc) {
        //capture iframe keystroke events
        this.iDoc = iDoc;
        this.iDoc.document.onkeyup = this.delegateHandler.bind(this);
        this.iDoc.document.onkeydown = this.delegateHandler.bind(this);
    },

    delegateHandler: function(event) {

        /* get real target - target in event object is wrong */

        //@todo this is not quite there - sometimes it returns a ul; also, I
        //      couldn't overwrite event.target
        //@todo target may be be UL or BODY on return key!
        var range, target;
        //trident?
        if (this.iDoc.document.selection) {
            range = this.iDoc.document.selection.createRange();
            target = range.parentElement();
        }
        //gecko, webkit, others?
        else if (this.iDoc.window.getSelection) {
            range = this.iDoc.window.getSelection().getRangeAt(0);
            var rangeParent = range.commonAncestorContainer;
            var rangeGrandParent = range.commonAncestorContainer.parentNode;


            //common select valid target
            if (rangeParent.tagName == 'LI' || rangeParent.tagName == 'P')
                target = rangeParent
            else target = rangeGrandParent
        }

        /* invoke proper handlers */

        //keydown events
        if (event.type == "keydown") {
            switch (event.keyCode) {
                case Event.KEY_TAB:
                    this.onTab(event, target, range);
                    break;
                case Event.KEY_BACKSPACE:
                    this.onBackspace(event, target, range);
                    break;
                case Event.KEY_DELETE:
                    this.onDelete(event, target, range);
                    break;
//                case 86: //v
//                    if (event.ctrlKey) {
//                        this.onPaste(event, target, range);
//                        break;
//                    }
                case 88: //x
                    if (event.ctrlKey) {
                        this.onCut(event, target, range);
                        break;
                    }
//                case 67: //c
//                    if (event.ctrlKey) {
//                        this.onCopy(event, target, range);
//                        break;
//                    }

                /* handles ranges of keys */
                default:

                    /* punc */
                    if (event.keyCode >=188 && event.keyCode <=122)
                        this.onDelete(event, null, range);

                    /* letters */
                    else if (event.keyCode >=65 && event.keyCode <=90)
                        this.onDelete(event, null, range);

                    /* numbers */
                    else if (event.keyCode >=48 && event.keyCode <= 57)
                        this.onDelete(event, null, range);

                    /* math */
                    else if (event.keyCode >=107 && event.keyCode <=111)
                        this.onDelete(event, null, range);

                    break;
            }
        }

        //keyup events
        else {

            switch (event.keyCode) {
                //down event caught
                case Event.KEY_TAB:break;

                case Event.KEY_UP:break;
                case Event.KEY_DOWN:break;
                case Event.KEY_LEFT:break;
                case Event.KEY_RIGHT:break;
                case 16:break; //shift
                case 17:break; //ctrl
                
                //normal letter behavior for backspace (rerendering card, etc)
                //case Event.KEY_BACKSPACE:break;

                //normal behavior for return - allow rerendering when splitting card
                //case Event.KEY_RETURN:break;

                //all other chars to be treated as letters
                default:this.onLetter(event, target, range);
            }
        }

        /* special handling for re-synchronizing right rail */

        //check if multiple nodes are in selection
        //gecko, webkit, others?
        if (   range
            //&& range.endOffset > range.startOffset
            && range.startContainer != range.endContainer
            && range.commonAncestorContainer
            && range.commonAncestorContainer.tagName != 'Text'
            && range.commonAncestorContainer.tagName != undefined) {

            //key code check
            if (   event.keyCode != Event.KEY_UP
                && event.keyCode != Event.KEY_DOWN
                && event.keyCode != Event.KEY_LEFT
                && event.keyCode != Event.KEY_RIGHT
                && event.keyCode != 16     //shift
                && event.keyCode != 17) {  //ctrl
                
                (function () {doc.rightRail.sync();}).delay(.1);
            }
        }
    },

    onTab: function(event, target, range) {

        /* ignore if not at beginning of node */
//        if (range.startOffset != 0) {
//            Event.stop(event);
//            event.preventDefault();
//            return;
//        }
        //@todo determine how to overide default tab event

        /* fire indent/outdent */
        if (event.shiftKey) doc.editor.execCommand('outdent');
        else doc.editor.execCommand('indent');
    },

    onLetter: function(event, target, range) {

        /* autosave */
        doc.outline.autosave();

        /* fire onDelete if selection */
        if (   range.commonAncestorContainer.nodeName != '#text'
            && range.startOffset != range.endOffset) {

            console.log('letter with selection, delete!');
            this.onDelete(event, null, range);
        }

        /* card creation, card update, catch invalid targets */

        //get core attributes
        var id = Element.readAttribute(target, 'id') || null;

        /* invalid target */
        if (target.tagName != 'P' && target.tagName != 'LI') {
            console.log('error: invalid target tag type');
            return;
        }

        /* set outline changed attribute, unsaved changes list */
        if (target.id != '') {
            Element.writeAttribute(target, {'changed': '1'});
            doc.outline.unsavedChanges.push(target.id)
        }

        /* new/existing card handling */

        //new card
        if (!id) doc.rightRail.createCard(target);

        //existing card
        else if (doc.rightRail.cards.get(id)) {
            doc.rightRail.focus(id);
            doc.rightRail.cards.get(id).update(target);
        }

        //error
        else console.log('error: node has id but no card exists')
    },

    onBackspace: function(event, target, range) {

        /* treat as delete if selection */
        if (   range.commonAncestorContainer.nodeName != '#text'
            || range.startOffset != range.endOffset) {

            this.onDelete(event, null, range);
            return;
        }

        /* take no action if not at beginning of node */
        if (range.startOffset != 0) return;

        /* indented paragraph handling */
        else if (target.tagName == 'P') {
            //indented
            if (Element.getStyle(target, 'margin-left') != '0px') {
                doc.editor.execCommand('outdent');
                Event.stop(event);
            }

            //not indented
            else {
                
                //first element in body - stop event
                if (Element.previousSiblings(target).length == 0) Event.stop(event);
                
                //delete node which already has id
                else if (target.getAttribute('line_id') != '')
                    doc.outline.deleteNodes.push(target.getAttribute('line_id'));

                //delete node which hadn't yet been saved
                else {/* normal behavior */}
            }
        }

        /* li handling */
        else if (target.tagName == 'LI') {
            doc.editor.execCommand('outdent');
            Event.stop(event);
        }
    },

    onCut: function(event, target, range) {
        
        /* treat as deletion */
        this.onDelete(event,target, range)
    },

    onDelete: function(event, target, range) {

        /* string representation of deleted text */
        var html = new XMLSerializer().serializeToString(range.cloneContents());

        /* delete with nothing highlighted */
        //check target because this may be invoked when pasting on top of something, etc..
        if (html == '' && target) {

            /* end of node? */
            if (   target.firstChild.nodeName == '#text' && range.endOffset == target.firstChild.length
                || target.firstChild.nodeName != '#text' && range.endOffset == 0) {

                //@todo implement delete at end of line - must push deleted node into delete queue
                Event.stop(event);
            }

            /* not end of node */
            else {/* normal behavior */}

        }

        /* push line ids in deleted html indo deleteNodes array */
        //don't bother checking if range parent is text
        else if (range.commonAncestorContainer.nodeName != '#text') {

            html.scan(/line_id="([^"]*)"/, function(match) {
                if (match[1]) doc.outline.deleteNodes.push(match[1]);
            });
        }
    },

    // @note listener set in view on editor creation
    onPaste: function(event) {

        /* if stuff highlighted, fire delete handler */
        var range;
        if (this.iDoc.document.selection) range = this.iDoc.document.selection.createRange(); //trident
        else if (this.iDoc.window.getSelection) range = this.iDoc.window.getSelection().getRangeAt(0); //gecko, webkit, others?

        /* run on delete to remove highlighted nodes */
        this.onDelete(event, null, range)

        /* prepare html */
        var html = event.data.html;
        
        //remove line ids
        html = html.gsub(/line_id="[^"]*"/, 'line_id=""');
        //set as changed
        html = html.gsub(/changed="[^"]*"/, 'changed="1"');
        //clear id
        html = html.gsub(/id="[^"]*"/, 'id=""');
        //clear parent node id
        html = html.gsub(/parent="[^"]*"/, 'parent=""');
        //remove meta tags - necessary?
        html = html.gsub(/<meta[^>]*>/, '');
        event.data.html = html;
    }
});

var cRightRail = Class.create({

    cardCount: 2,
    cards: new Hash(),
    inFocus: null,

    initialize: function() {
        
        /* render listener */
        $('sync_button').observe('click', this.sync.bind(this));

        /* run sync - for if reading */
        document.observe('editor:loaded', function() {

            /* set card count */
            var nodes = Element.select(doc.outline.iDoc.document, 'li, p')
                .each(function (node) {
                    var index = parseInt(node.id.replace('node_', ''));
                    if (index >= this.cardCount) this.cardCount = index + 1;
                }.bind(this));

            /* sync */
            this.sync();
        }.bind(this));
    },

    createCard: function(node) {

        //check node is valid
        if (   node.tagName.toUpperCase() != 'LI'
            && node.tagName.toUpperCase() != 'P') return;

        this.cards.set('node_' + this.cardCount, new cCard(node, this.cardCount));
        this.focus(this.cardCount++);
    },

    focus: function(id) {

        //normalize id
        var cardId = doc.utilities.toCardId(id);

        //check card exists
        if (!$(cardId)) {
            console.log("error: can't focus on non-existent card");
            return;
        }

        //scroll function
        var rightRail = document.getElementById("right_rail");
        var scrollTo = function () {
            rightRail.scrollTop = this.inFocus.offsetTop
                - this.inFocus.getHeight()
                - $('right_rail').getHeight()/2
                - 10;
        }.bind(this);

        //check if already in focus - if so, just make sure scrollTtop is still correct
        if(this.inFocus && this.inFocus.id == cardId) {
            scrollTo();
            return;
        }

        //unfocus previously focused
        else if(this.inFocus && this.inFocus.id != cardId) {
            Element.removeClassName(this.inFocus, 'card_focus');
            var nodeIdPrev = doc.utilities.toNodeId(this.inFocus);
            var nodePrev = doc.outline.iDoc.document.getElementById(nodeIdPrev);
            if (this.cards.get(nodeIdPrev)) this.cards.get(nodeIdPrev).update(nodePrev, true);
            else console.log('error: cannot unfocus previous card');
        }

        //focus
        this.inFocus = $(cardId);
        Element.addClassName(this.inFocus, 'card_focus');
        scrollTo();
    },

    /* render right rail - should not be called unless dones so explicitly by
     * user or the rail cards are no longer in sync with the  */
    sync: function() {

        /* collect all potential nodes - li/p with text */
        var nodes = Element.select(doc.outline.iDoc.document, 'li, p')
            .findAll(function (node) {return node.innerHTML});

        /* either create or refresh all nodes */
        nodes.each(function(node) {

            //new node, new card
            if (!node.id)
                this.cards.set('node_' + this.cardCount, new cCard(node, this.cardCount++, true));

            //existing node, new card
            else if (!this.cards.get(node.id)) {
                var cardIndex = parseInt(node.id.replace('node_', ''));
                var attributes = {'line_id': node.getAttribute('line_id'),
                                  'changed': node.getAttribute('changed'),
                                  'active': node.getAttribute('active'),
                                  'id': node.getAttribute('id')}
                this.cards.set(node.id, new cCard(node, cardIndex, true, attributes));
            }

            //update existing card
            else {

                //truncate boolean true unless node being updated is in focus
                var truncate =
                       !this.inFocus
                    || doc.utilities.toNodeId(this.inFocus.id) != node.id;

                //update
                this.cards.get(node.id).update(node, truncate);
            }

            /* parent attribute setter */
            //@todo backend should be able to handle this, in which case sync
            //      would not need to be run before save. the placement of this
            //      logic here is ontologically wrong
            doc.outline.iDoc.document.body.setAttribute("id","node_0"); //@todo can be placed in outline initialization if this strat remains
            var parent = (node.parentNode.tagName != "UL")
                ? node.parentNode
                : node.parentNode.parentNode;
            node.setAttribute("parent", parent.id);
        }.bind(this));

        /* destroy cards if node no longer exists */
        this.cards.each(function(cardArray) {
            var nodeId = cardArray[0];
            var card = cardArray[1];
            var node = doc.outline.iDoc.document.getElementById(nodeId);
            if (!node) card.destroy();
        });

    }
});

var cCard = Class.create({

    cardNumber: null,

    front: '',
    back: '',
    text: '',

    active: false,
    elmntCard: null,
    elmntNode: null,
    updating: false,

    autoActivate: false,
    autoActivated: false,    //if auto activated and later format becomes unnacceptable - autoDeactivate

    parser: null,

    initialize: function(node, cardCount, truncate, attributes) {

        /* set count */
        this.cardNumber = cardCount;

        /* set dom node attributes */
        var defaultAttributes = $H({'id': 'node_' + this.cardNumber,
                                    'line_id':'',
                                    'changed': '0',
                                    'active': false});
        attributes = defaultAttributes.merge(attributes).toObject();
        Element.writeAttribute(node, attributes);
        Element.addClassName(node, 'outline_node');

        /* card in dom */
        var cardHtml = '<div id="card_' + this.cardNumber + '" class="rounded_border card"></div>';
        this._insert(cardHtml);
        this.elmntCard = $("card_" + this.cardNumber);
        
        /* set active - in case regenerating card for existing node */
        if (node.getAttribute('active') == 'true') this.activate();

        /* update */
        this.update(node, truncate);
    },

    update: function(node, truncate) {

        //node exists?
        if (!node) {
            this.destroy();
            return;
        }

        this.active = node.getAttribute('active') == "true";
        
        //parse and render
        this.text = node.innerHTML.match(/^([^<]*)<?/)[1];
        parser.parse(this);
        this.render(truncate);
    },

    activate: function() {
        this.active = true;
        $('card_' + this.cardNumber).addClassName('card_active');
        this.render();
    },

    deactivate: function() {
        this.active = false;
        $('card_' + this.cardNumber).removeClassName('card_active');

        var truncate = !this.inFocus || this.inFocus.id != 'card_' + this.cardNumber
        this.render(truncate);
    },

    render: function(truncate) {

        //checkbox
        var checkbox;
        if (this.active == true) checkbox = '<input type="checkbox" class="card_activation" checked="yes" />';
        else checkbox = '<input type="checkbox" class="card_activation" />';

        //truncated txt
        if (truncate && !this.active) {
            this.elmntCard.innerHTML
                = checkbox + this.text;
        }

        //both sides set
        else if (this.back) {
            this.elmntCard.innerHTML = '<div class="card_front">'
                    + checkbox + this.front + '</div>\
                <div class="card_back">'+this.back+'</div>';

            //autoActivate
            if (this.autoActivate) {
                this.autoActivated = true;
                this.autoActivate = false;
                this.activate();
                this.elmntCard.down('input').checked = 'yes';
                doc.outline.iDoc.document.getElementById('node_' + this.cardNumber).setAttribute('active', true);
            }
        }

        //just front
        else if (this.elmntCard) {
            this.elmntCard.innerHTML = '<div class="card_front">'
                + checkbox + this.front + '</div>';

            //autoDeactivate
            if (this.autoActivated) {
                this.autoActivated = false;
                this.deactivate();
                this.elmntCard.down('input').checked = '';
                doc.outline.iDoc.document.getElementById('node_' + this.cardNumber).setAttribute('active', false);
            }
        }

        //no card to update
        else console.log('error: cannot render - no card in dom to update')

    },

    destroy: function() {
        Element.remove(this.elmntCard);
        doc.rightRail.cards.unset('node_' + this.cardNumber);
    },

    _insert: function(cardHtml) {

        /* identify previous node in outline */

        //collect nodes which have cards
        var nodeId = 'node_' + this.cardNumber;
        var outlineNodes = $A(doc.outline.iDoc.document.getElementsByClassName('outline_node'))
            .findAll(function(node) {return node.id});

        //itererate backwards to find previous node; set id vars
        var outlineNodePrev, nodeIdPrev, cardIdPrev;
        for (var i = outlineNodes.length - 1; i >= 0; i--) {
            if (outlineNodes[i].id == nodeId && i != 0) {
                outlineNodePrev = outlineNodes[i-1];
                nodeIdPrev = outlineNodePrev.id;
                cardIdPrev = "card_" + nodeIdPrev.replace('node_', '');
                break;
            }
        }

        //insert first
        if (!cardIdPrev) $('cards').insert({top: cardHtml});

        //previous node but no previous card
        else if (cardIdPrev && !$(cardIdPrev)) {

            //@todo create previous card if does not exist
            console.log('error: no previous card but there should be!');

            //temp
            $('cards').insert({bottom: cardHtml});
        }

        //insert later
        else $(cardIdPrev).insert({after: cardHtml});
    }
});

var cUtilities = Class.create({

    toNodeId: function(mixed) {
        var id = this._getId(mixed);
        if (id || id == 0) return 'node_' + id;
    },

    toCardId: function(mixed) {
        var id = this._getId(mixed);
        if (id || id == 0) return 'card_' + id;
    },

    _getId: function(mixed) {

        var id;

        //node or card
        if (Object.isElement(mixed)) id = mixed.id.replace('node_', '').replace('card_', '');

        //id
        else if (Object.isNumber(mixed)) id = mixed;

        //nodeId or cardId
        else if (Object.isString(mixed)) var id = mixed.replace('node_', '').replace('card_', '');

        return id;
    }
});

/* global objects */
document.observe('dom:loaded', function() {
    parser = new cParser();
    doc = new cDoc();
});
