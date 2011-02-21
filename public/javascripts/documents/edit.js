/* class declarations */

var cDoc = Class.create({

    outline: null,
    rightRail: null,
    editor: null,
    utilities: null,

    newDoc:null,

    initialize: function() {

        /* set new document attr */
        var newDoc = $('new_document');
        if (newDoc) {

            /* set attr and remove node (in case there are edits followed by reload) */
            this.newDoc = true;
            newDoc.remove();
        }
        else newDoc = false;

        /* load editor */
        this.loadEditor();

        /* select all in doc name on click */
        $('document_name').observe('click', function(e) {e.target.select();});
    },

    loadEditor: function() {

      window.CKEDITOR_BASEPATH = '/javascripts/ckeditor/';
      CKEDITOR.replace( 'editor', {
        startupFocus : !this.newDoc,
        customConfig: '',
        contentsCss: '/stylesheets/documents/edit_contents.css',
        removePlugins: 'elementspath',
        resize_enabled: false,
        language: 'en',

        toolbar:  [

            ['BulletedList','-','Outdent','Indent'],
            ['Bold','Italic','Underline'],//,'Strike'],
            ['JustifyLeft','JustifyCenter','JustifyRight']//,'JustifyBlock'],
            //['Undo','Redo'],
            //['Cut','Copy','Paste','-','Print', 'SpellChecker'],
            //['Link','Unlink'],
            //['SpecialChar']
        ],

        on: {
          instanceReady : function(e) {doc.onEditorLoaded();},
          paste: function(e) {doc.outline.outlineHandlers.onPaste(e)}
        }
      });
    },

    onEditorLoaded: function() {

        /* member objects */
        this.utilities = new cUtilities();
        this.editor = CKEDITOR.instances.editor;

        // @todo this creates race condition - look for callback - ugglie!!!
        (function () {

            /* load outline obj */
            this.outline = new cOutline();

            /* initialize right rail once editor loaded */
            this.rightRail = new cRightRail();

            /* focus and select sample node if exists */
            if (this.newDoc) {
                var handler = function() {

                    /* sample node, clear */
                    var sampleNode = Element.select(doc.outline.iDoc.document, 'li')[0];
                    sampleNode.innerHTML = '<br />';
//                    doc.editor.focus();

                    /* update card when interpreter available */
                    var card = doc.rightRail.cards.get(sampleNode.id);
                    card.update.bind(card).defer(sampleNode);

                    /* stop observing */
                    Element.stopObserving.defer(doc.outline.iDoc.document, 'click', handler);
                };
                Element.observe(doc.outline.iDoc.document, 'click', handler);
            }
        }.bind(this)).delay(.1);

        /* resize listener */
        window.onresize = this.onResize;
        this.onResize();
    },

    onResize: function() {

        /* set to visible */
        var editorContainer = $('editor_container');
        var rightRail = $('right_rail');
        editorContainer.show();
        rightRail.show();

        /* calculations */
        var bottomMargin = 20;
        var editorContainerHeight = parseInt(editorContainer.getStyle('height'));
        var editorVerticalSpaceHeight = document.viewport.getDimensions()['height']
            - editorContainer.cumulativeOffset().top - bottomMargin;
        var editorWhitespace = $('cke_contents_editor');

        /* set minimums */
        if (editorVerticalSpaceHeight < 200) editorVerticalSpaceHeight = 200;

        /* set heights */
        editorWhitespace.setStyle({height: editorVerticalSpaceHeight - 49 + 'px'});
        rightRail.setStyle({height: editorVerticalSpaceHeight - 2 + 'px'});
        $('cke_editor').setStyle({height: editorVerticalSpaceHeight - 2 + 'px'});
//        $('right_rail').setStyle({height: editorVerticalSpaceHeight + 'px !important'});


    }
});

var cOutline = Class.create({

    iDoc: null,
    outlineHandlers: null,

    documentId: null,

    maxIdle: 12,
    idleSaveTimerId: null,
    maxActive: 30,
    activeSaveTimerId: null,

    unsavedChanges: [],  //list of domIds for unsaved changes
    savingChanges: [],  //list of domIds for changes sent to server (request in progress)

    deleteNodes: [],  //list of domIds for nodes to be delete
    deletingNodes: [],  //list of domIds for nodes currently being deleted (request in progress)

    newNodes: false, //boolean tracks whether new nodes have been added

    lineIds: null,

    initialize: function() {

        /* document members */
        this.documentId = $('document_id').innerHTML;
        this.lineIds = $H($('line_ids').innerHTML.evalJSON());

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

    autosave: function(force) {

        /* idle save timer */
        window.clearTimeout(this.idleSaveTimerId);
        this.idleSaveTimerId = this.save.bind(this, force).delay(this.maxIdle);

        /* idle save timer */
        if (this.activeSaveTimerId == null)
            this.activeSaveTimerId = this.save.bind(this, force).delay(this.maxActive);

        /* save button styling */
        $('save_button').innerHTML = 'Save';

        /* navigate away while saving warning */
        window.onbeforeunload = function(e){
            return 'There is unsaved information on this page.';
        }
    },

    save: function(force) {

        /* cancel other timers */
        window.clearTimeout(this.idleSaveTimerId);
        window.clearTimeout(this.activeSaveTimerId);
        this.idleSaveTimerId = null;
        this.activeSaveTimerId = null;

        /* look for new lines and deleted lines */
        doc.outline.updateIds();

        /* don't save if nothing changed or save not being forced */
        var saveButton = $('save_button');
        if (   this.unsavedChanges.length == 0
            && this.deleteNodes.length == 0
            && !force
            && this.lineIds) {

            console.log('save canceled');
            saveButton.innerHTML = 'Saved';
            return;
        }

        console.log('save');

        /* sync */
        // @todo this may become unnecessary later on
        doc.rightRail.sync();

        /* save button styling */
        saveButton.disabled = true;
        saveButton.innerHTML = 'Saving';

        /* body outerHTML - workaround for firefox */
        var body = this.iDoc.document.getElementsByTagName('body')[0];
        var bodyClone = new Element('body', {'line_id': body.getAttribute('line_id'),
                                                   'id': 'node_0'});
        var bodyOuterHTML = bodyClone.update(body.innerHTML).wrap().innerHTML;

        /* save */
        new Ajax.Request('/documents/'+this.documentId, {
            method: 'put',
            parameters: {'html': bodyOuterHTML,
                         'name': $('document_name').value,
                         'delete_nodes': this.deleteNodes.toString(),
                         'new_nodes': this.newNodes},

            onCreate: function() {

                /* track saving changes */
                this.unsavedChanges = this.unsavedChanges.uniq();
                this.unsavedChanges.each(function(domId) {
                    if (domId && this.iDoc.document.getElementById(domId))
                        Element.writeAttribute(this.iDoc.document.getElementById(domId), {'changed': '0'});
                }.bind(this));
                this.savingChanges = this.unsavedChanges;
                this.unsavedChanges = [];

                /* track nodes being delete, clear nodes to be deleted */
                this.deletingNodes = this.deleteNodes;
                this.deleteNodes = [];

            }.bind(this),

            onSuccess: function(transport) {
                this.lineIds = $H(transport.responseText.evalJSON());
                this.updateIds();
                
                /* set new nodes to false */
                this.newNodes = false;

                /* save button styling */
                saveButton.disabled = false;
                saveButton.innerHTML = 'Saved';

                /* cancel navigate away while saving warning */
                window.onbeforeunload = null;
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

                /* save button styling */
                saveButton.disabled = false;
                saveButton.innerHTML = 'Save';
                this.autosave();

                console.log('error: unable to save');
            }.bind(this),

            onComplete: function() {

                /* clear saving changes */
                this.savingChanges = []
                this.deletingNodes = []
            }.bind(this)
        });
    },

    activateNode: function(checkbox) {

        //vars
        var card = checkbox.up('.card');
        var domId = doc.utilities.toNodeId(card);
        var node = this.iDoc.document.getElementById(domId);

        //activate/dactivate card
        if (checkbox.checked) {
            node.setAttribute('active', true);
            doc.rightRail.cards.get(domId).activate();
        }
        else {
            node.setAttribute('active', false);
            doc.rightRail.cards.get(domId).deactivate();
        }

        /* autosave */
        node.setAttribute('changed', '1');
        this.unsavedChanges.push(node.id);
        this.autosave();

        /* refocus on editor */
        doc.editor.focus();
    },

    updateIds: function() {

        /* don't run if no lineids */
        if (!this.lineIds) {
            console.log('cannot update ids');
            return;
        }
        else console.log('update ids');

        /* iterate through id, line_id hash */
        this.lineIds.each(function(idArray) {

            /* add id */
            if (this.iDoc.document.getElementById(idArray[1])) {
                this.iDoc.document.getElementById(idArray[1]).setAttribute('line_id', idArray[0]);
            }

            /* remove line if no node has the associated node id */
            else {

                this.deleteNodes.push(idArray[0]);
                console.log('deleting ' + idArray[0]);
            }
        }.bind(this));

        /* iterate through nodes, make sure line_id is in hash */
        Element.select(doc.outline.iDoc.document, '.outline_node').each(function(node) {

            /* parent attribute setter */
            doc.outline.iDoc.document.body.setAttribute("id","node_0"); // @todo can be placed in outline initialization if this strat remains
            var parent = (node.parentNode.tagName != "UL")
                ? node.parentNode
                : node.parentNode.parentNode;

            //set parent - if changed, treat node as new
            if (   node.getAttribute("parent")
                && node.getAttribute("parent") != parent.id) {

                console.log('reset line id and id');
                this.deleteNodes.push(node.getAttribute("line_id"));
                node.setAttribute("line_id", '');
                node.setAttribute("id", '');
            }
            node.setAttribute("parent", parent.id);

            /* treat nodes that aren't in returned hash as new - set doc as changed */
            if (   this.lineIds.get(node.getAttribute('line_id'))
                != node.id) {

                console.log('node not in hash; removing line_id');
                node.setAttribute('line_id', '');
                this.unsavedChanges.push(node.id);
            }

            /* assure all changed nodes in unsavedChanges - shouldn't be necessary */
            if (   node.getAttribute('changed') == '1'
                && this.unsavedChanges.indexOf(node.id) == -1) {

                console.log('adding node to unsavedChanges: ' + node.id);
                this.unsavedChanges.push(node.id);
            }

            /* new nodes */
            if (!node.getAttribute('line_id')) this.newNodes = true;
        }.bind(this));
    }
});

var cOutlineHandlers = Class.create({

    iDoc: null, // @todo repeated unfortunately - can't access in outline until initialization complete

    initialize: function(iDoc) {
        //capture iframe keystroke events
        this.iDoc = iDoc;
        this.iDoc.document.onkeyup = this.delegateKeystrokeHandler.bind(this);
        this.iDoc.document.onkeydown = this.delegateKeystrokeHandler.bind(this);
        this.iDoc.document.onkeypress = this.delegateKeystrokeHandler.bind(this);

        this.iDoc.document.onmouseup = this.delegateClickHandler.bind(this);
        this.iDoc.document.onmousedown = this.delegateClickHandler.bind(this);
    },

    getEventDetails: function() {

        /* get real target - target in event object is wrong */

        // @todo this is not quite there - sometimes it returns a ul; also, I
        //      couldn't overwrite event.target
        // @todo target may be be UL or BODY on return key!
        var range, target, spansMultiple;
        //trident?
        if (this.iDoc.document.selection) {
            range = this.iDoc.document.selection.createRange();
            target = range.parentElement();
        }
        //gecko, webkit, others?
        else if (this.iDoc.window.getSelection && this.iDoc.window.getSelection().rangeCount > 0) {
            range = this.iDoc.window.getSelection().getRangeAt(0);
            var rangeParent = range.commonAncestorContainer;
            var rangeGrandParent = range.commonAncestorContainer.parentNode;

            //common select valid target
            if (rangeParent.tagName == 'LI' || rangeParent.tagName == 'P')
                target = rangeParent
            else target = rangeGrandParent

            //set spansMultiple
            spansMultiple = range.startContainer != range.endContainer;
        }

        return [range, target, spansMultiple];
    },

    delegateKeystrokeHandler: function(event) {

        /* @browser fetch event for IE */
        if (!event) {event = doc.outline.iDoc.event;}

        /* event details */
        var eventDetails = this.getEventDetails();
        var range = eventDetails[0];
        var target = eventDetails[1];
        var spansMultiple = eventDetails[2];

        /* invoke proper handlers */

        //keydown events
        if (event.type == "keydown") {

            if (event.keyCode == Event.KEY_TAB)
                this.onTab(event, target, range);

            else if (Event.KEY_DELETE == event.keyCode)
                this.onDelete(event, target, range, spansMultiple);

            /* hyphen - make bulletedlist */
            else if ((189 == event.keyCode || 109 == event.keyCode) && range.startOffset == 0) 
                this.onHyphen(event, target, range);

            /* special backspace handling for highlighted text and beginning of nodes */
            else if (Event.KEY_BACKSPACE == event.keyCode)
                // @browser fire on keydown for all but opera
                if (!Prototype.Browser.Opera) this.onBackspace(event, target, range, spansMultiple);

            /* intercept arrow events */
            else if (   Event.KEY_UP == event.keyCode
                     || Event.KEY_DOWN == event.keyCode
                     || Event.KEY_LEFT == event.keyCode
                     || Event.KEY_RIGHT == event.keyCode) ;

            /* treat like letter */
            else if (Event.KEY_RETURN == event.keyCode)
                this.onLetter(event, target, range);

            /* intecept certain letters - take no action here */
            else if (67 == event.keyCode && event.ctrlKey) ; //copy
            else if (86 == event.keyCode && event.ctrlKey) ; //paste
            else if (88 == event.keyCode && event.ctrlKey) ; //cut
            else if (89 == event.keyCode && event.ctrlKey) ; //redo
            else if (90 == event.keyCode && event.ctrlKey) ; //undo

            /* letter like */
            else if (   event.keyCode == 32 /* space */
                     || event.keyCode >= 186 && event.keyCode <= 222 /* punc */
                     || event.keyCode >= 65 && event.keyCode <= 90 /* letters */
                     || event.keyCode >= 48 && event.keyCode <= 57 /* numbers */
                     || event.keyCode >= 107 && event.keyCode <= 111) /* math */

                this.onDelete(event, target, range, spansMultiple);
        }

        //keyup events
        else if (event.type == "keyup") {

            if (Event.KEY_TAB == event.keyCode) ; /* nothing */

            /* return keyup target is new node */
            else if (Event.KEY_RETURN == event.keyCode) {
                this.onDelete(event, null, range, spansMultiple);
                this.onLetter(event, target, range);
            }

            /* intercept arrow events */
            else if (   Event.KEY_UP == event.keyCode
                     || Event.KEY_DOWN == event.keyCode
                     || Event.KEY_LEFT == event.keyCode
                     || Event.KEY_RIGHT == event.keyCode) ;

            /* ordered list */
            else if (55 == event.keyCode && event.ctrlKey && event.shiftKey) {
                doc.editor.execCommand('numberedlist');
                doc.outline.autosave(true);
            }

            /* unordered list */
            else if (56 == event.keyCode && event.ctrlKey && event.shiftKey) {
                doc.editor.execCommand('bulletedlist');
                doc.outline.autosave(true);
            }

            /* intecept certain letters - take no action here */
            else if (67 == event.keyCode && event.ctrlKey) ; //copy
            else if (86 == event.keyCode && event.ctrlKey) ; //paste
            else if (88 == event.keyCode && event.ctrlKey) ; //cut

            /* undo/redo trigger save */
            //redo
            else if (89 == event.keyCode && event.ctrlKey) {
                console.log('redo autosave');
                doc.outline.autosave(true);
            }

            //undo
            else if (90 == event.keyCode && event.ctrlKey) {
                console.log('undo autosave');
                doc.outline.autosave(true);
            }

            /* hyphen - make bulletedlist - cancel keyup event*/
            else if ((189 == event.keyCode || 109 == event.keyCode) && range.startOffset == 0) ;

            /* letter like keys */
            else if (   event.keyCode == 32 /* space */
                     || event.keyCode >= 186 && event.keyCode <= 222 /* punc */
                     || event.keyCode >= 65 && event.keyCode <= 90 /* letters */
                     || event.keyCode >= 48 && event.keyCode <= 57 /* numbers */
                     || event.keyCode >= 107 && event.keyCode <= 111) /* math */

                this.onLetter(event, target, range);
        }

        //keypress events
        else if (event.type == "keypress") {

            /* @browser weird ckeditor in OPERA - must intersept keyCode 45!!! */
            if (45 == event.keyCode && range.startOffset == 0) 
                if (Prototype.Browser.Opera) Event.stop(event);

            /* @browser opera silence backspace for keypress (unless beginning of line) */
             if (Event.KEY_BACKSPACE == event.keyCode)
                if (Prototype.Browser.Opera) this.onBackspace(event, target, range, spansMultiple);
        }
    },

    delegateClickHandler: function(event) {

        /* @browser fetch event for IE */
        if (!event) {event = doc.outline.iDoc.event;}

        /* event details */
        var eventDetails = this.getEventDetails();
        var range = eventDetails[0];
        var target = eventDetails[1];
        var spansMultiple = eventDetails[2];

        /* mouse up events */
        if (event.type == 'mouseup')
            this.onDragNode(event, target, range);

        /* mouse down events */
        else this.onClickNode(event, target, range);
    },

    onTab: function(event, target, range) {

        console.log('tab');

        /* ignore if not at beginning of node */
        if (range.startOffset != 0) {
            Event.stop(event);
            (function() {doc.editor.focus();}).delay(.01);
            return;
        }
        // @todo determine how to overide default tab event

        /* fire indent/outdent */
        if (event.shiftKey) doc.editor.execCommand('outdent');
        else doc.editor.execCommand('indent');

        /* autosave */
        console.log('tab autosave');
        doc.outline.autosave();

        /* reset focus - delay required for opera*/
        (function() {doc.editor.focus();}).delay(.1);
    },

    onLetter: function(event, target, range) {

        /* autosave */
        console.log('onLetter autosave');
        doc.outline.autosave(true);

        /* card creation, card update, catch invalid targets */

        //get core attributes
        var id = Element.readAttribute(target, 'id') || null;

        /* invalid target */
        if (target.tagName != 'P' && target.tagName != 'LI') {
            console.log('error: invalid target tag type');
            return;
        }

        /* set outline changed attribute, unsaved changes list */
        Element.writeAttribute(target, {'changed': '1'});
        doc.outline.unsavedChanges.push(target.id);

        /* new/existing card handling */

        //new card
        if (!id) doc.rightRail.createCard(target);

        //existing card
        else if (doc.rightRail.cards.get(id)) doc.rightRail.updateFocusCardWrapper(id, target);

        //error
        else console.log('error: node has id but no card exists');
    },

    onBackspace: function(event, target, range, spansMultiple) {

        /* run delete to handle cases where text is being overwritten */
        this.onDelete(event, null, range, spansMultiple);

        /* just update card if not at beginning of node */
        if (range.startOffset != 0) {
            /* update node */
            var id = Element.readAttribute(target, 'id') || null;
            if (doc.rightRail.cards.get(id)) doc.rightRail.updateFocusCardWrapper(id, target);
            return;
        }

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
                console.log(Element.previousSiblings(target).length);
                if (Element.previousSiblings(target).length == 0) Event.stop(event);

                //delete node/card
                else doc.rightRail.sync.bind(doc.rightRail).delay(.25);
            }
        }

        /* li handling */
        else if (target.tagName == 'LI') {
            console.log('backspace li');
            doc.editor.execCommand('outdent');
            Event.stop(event);
        }

        /* autosave */
        console.log('backspace autosave');
        doc.outline.autosave();
    },

    onDelete: function(event, target, range, spansMultiple) {

        /* autosave */
        console.log('onDelete autosave');
        doc.outline.autosave(true);

        /* string representation of deleted text */
        var html;
        if (Prototype.Browser.IE) {
            html = range.htmlText;
        }
        else html = new XMLSerializer().serializeToString(range.cloneContents());

        /* delete with nothing highlighted */
        //check target because this may be invoked when pasting on top of something, etc..
        if (html == '' && target) {

            /* end of node? */
            if (   target.firstChild.nodeName == '#text' && range.endOffset == target.firstChild.length
                || target.firstChild.nodeName != '#text' && range.endOffset == 0) {

                // @todo implement delete at end of line - must push deleted node into delete queue
                Event.stop(event);
            }

            /* not end of node */
            else {
                doc.outline.unsavedChanges.push(target.id);
                console.log('setting changed. target: ' + target);
                target.setAttribute('changed', 1);

                /* update node */
                var id = Element.readAttribute(target, 'id') || null;
                if (doc.rightRail.cards.get(id)) doc.rightRail.updateFocusCardWrapper(id, target);
            }
        }

        /* check for partial delete of first node in range */
        else {

            // @browser identify start container
            if (Prototype.Browser.IE) {
                var matches = html.match(/<[^>]* id=([^\s]+)[^>]*>/);
                if (matches) {
                    var startContainer = doc.outline.iDoc.document.getElementById(matches[1]);
                    if (startContainer) {
                        startContainer.parentNode.setAttribute('changed', 1);
                    }
                }
            }
            else {
                doc.outline.unsavedChanges.push(range.startContainer.parentNode.id);
                range.startContainer.parentNode.setAttribute('changed', 1);
            }
        }

        /* resync if delete called with selection spanning multiple nodes */
        if (spansMultiple) doc.rightRail.sync.bind(doc.rightRail).defer();

        /* autosave */
        console.log('delete (or before char) autosave');
        doc.outline.autosave();
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
    },

    onClickNode: function(event, target, range) {},

    onDragNode: function(event, target, range) {

//        /* check for change in parents */
//        Element.select(doc.outline.iDoc.document, '.outline_node').each(function(node) {
//
//            /* parent attribute setter */
//            var parent = (node.parentNode.tagName != "UL")
//                ? node.parentNode
//                : node.parentNode.parentNode;
//
//            //set parent - if changed, treat node as new
//            if (   node.getAttribute("parent")
//                && node.getAttribute("parent") != parent.id) {
//
//                /* auto save */
//                console.log('change in parents detected');
//                doc.outline.autosave(true);
//            }
//        });
    },

    /* called when a hypen is pressed at beginning of node */
    onHyphen: function(event, target, range) {

        /* stop event */
        Event.stop(event);

        /* exec bulletlist ckeditor command */
        doc.editor.execCommand('bulletedlist');
    }
});

var cRightRail = Class.create({

    cardCount: 2,
    cards: new Hash(),
    inFocus: null,

    updateFocusCardTimer: null,

    initialize: function() {
        
        /* render listener */
        $('sync_button').observe('click', this.sync.bind(this));

        /* set card count */
        var nodes = Element.select(doc.outline.iDoc.document, 'li, p')
            .each(function (node) {
                var index = parseInt(node.id.replace('node_', ''));
                if (index >= this.cardCount) this.cardCount = index + 1;
            }.bind(this));

        /* sync */
        this.sync();

        /* activate card */
        document.observe('click', function(event) {
           if(event.target.hasClassName('card_activation')) doc.outline.activateNode(event.target);
        }.bind(this));
    },

    /* wrapper function for focus/update to limit the number of calls! */
    updateFocusCardWrapper: function(id, target) {

        /* clear timer */
        window.clearTimeout(this.updateFocusCardTimer)

        /* make call */
        this.updateFocusCardTimer =
            (function () {
                doc.rightRail.focus(id);
        doc.rightRail.cards.get(id).update(target, false, true);
            }).delay(.25)
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
            var domIdPrev = doc.utilities.toNodeId(this.inFocus);
            var nodePrev = doc.outline.iDoc.document.getElementById(domIdPrev);
            if (this.cards.get(domIdPrev)) this.cards.get(domIdPrev).update(nodePrev, true);
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
        }.bind(this));

        /* destroy cards if node no longer exists */
        this.cards.each(function(cardArray) {
            var domId = cardArray[0];
            var card = cardArray[1];
            var node = doc.outline.iDoc.document.getElementById(domId);
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
    domId: null,
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

        /* set domId */
        this.domId = node.id;

        /* card in dom */
        var cardHtml = '<div id="card_' + this.cardNumber + '" class="rounded_border card"></div>';
        this._insert(cardHtml);
        this.elmntCard = $("card_" + this.cardNumber);
        
        /* set active - in case regenerating card for existing node */
        if (node.getAttribute('active') == 'true') this.activate();

        /* update */
        this.update(node, truncate);
    },

    update: function(node, truncate, contextualize) {

        //node exists?
        if (!node) {
            this.destroy();
            return;
        }

        this.active = node.getAttribute('active') == "true";
        
        /* parse and render */
        this.text = node.innerHTML.match(/^([^<]*)<?/)[1];

        // @todo for now ignore contextualizing active card
        parser.parse(this, false, true);

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

        /* checkbox dom */
        var checkbox;
        if (this.active == true) checkbox = '<input type="checkbox" class="card_activation" checked="yes" />';
        else checkbox = '<input type="checkbox" class="card_activation" />';

        /* attempt autoactivate */
        if (this.autoActivate) {
            this.autoActivated = true;
            this.autoActivate = false;
            this.activate();
            this.elmntCard.down('input').checked = 'yes';
            console.log('activate in render');
            doc.outline.iDoc.document.getElementById('node_' + this.cardNumber).setAttribute('active', true);
        }

        //is active
        if (!this.active)
            this.elmntCard.innerHTML = checkbox + '<i>Click checkbox to activate</i>';

        //truncated txt
        else if (truncate && !this.active) {
            this.elmntCard.innerHTML
                = checkbox + this.text;
        }

        //both sides set
        else if (this.back) {
            this.elmntCard.innerHTML = '<div class="card_front">'
                    + checkbox + '</div>\
                <div class="card_back">'+this.back+'</div>';
            this.elmntCard.down().insert(this.front);
        }

        //just front
        else if (this.elmntCard) {
            this.elmntCard.innerHTML = '<div class="card_front">'
                + checkbox + '</div>';
            this.elmntCard.down().insert(this.front);

            //autoDeactivate
            if (this.autoActivated) {
                this.autoActivated = false;
                this.deactivate();
                this.elmntCard.down('input').checked = '';
                console.log('activate in render');
                doc.outline.iDoc.document.getElementById('node_' + this.cardNumber).setAttribute('active', false);
            }
        }

        //no card to update
        else {
            console.log('error: cannot render - no card in dom to update')
            return;
        }

    },

    destroy: function() {
        Element.remove(this.elmntCard);
        doc.rightRail.cards.unset('node_' + this.cardNumber);
    },

    _insert: function(cardHtml) {

        /* identify previous node in outline */

        //collect nodes which have cards
        var domId = 'node_' + this.cardNumber;
        var outlineNodes = Element.select(doc.outline.iDoc.document, '.outline_node');
        outlineNodes = $A(outlineNodes).findAll(function(node) {return node.id});

        //itererate backwards to find previous node; set id vars
        var outlineNodePrev, domIdPrev, cardIdPrev;
        for (var i = outlineNodes.length - 1; i >= 0; i--) {
            if (outlineNodes[i].id == domId && i != 0) {
                outlineNodePrev = outlineNodes[i-1];
                domIdPrev = outlineNodePrev.id;
                cardIdPrev = "card_" + domIdPrev.replace('node_', '');
                break;
            }
        }

        //insert first
        if (!cardIdPrev) $('cards').insert({top: cardHtml});

        //previous node but no previous card
        else if (cardIdPrev && !$(cardIdPrev)) {

            // @todo create previous card if does not exist
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

        //domId or cardId
        else if (Object.isString(mixed)) var id = mixed.replace('node_', '').replace('card_', '');

        return id;
    }
});

/* global objects */
document.observe('dom:loaded', function() {
    parser = new cParser();
    doc = new cDoc();

    /* fire app:loaded */
    document.fire('app:loaded');
});