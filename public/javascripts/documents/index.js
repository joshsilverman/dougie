var cDoc = Class.create({

    outline: null,
    rightRail: null,
    editor: null,
    utilities: null,

    initialize: function() {

        //wait for ckeditor to load
        document.observe('CKEDITOR:ready', function() {
            this.utilities = new cUtilities();
            this.editor = CKEDITOR.instances.editor;
            this.rightRail = new cRightRail();

            //@todo this creates race condition - look for callback - ugglie!!!
            (function () {this.outline = new cOutline();}.bind(this)).delay(.1);
        }.bind(this));
    }
});

var cOutline = Class.create({

    iDoc: null,
    outlineHandlers: null,

    initialize: function() {
        
        //iframe doc
        var iframe = $$('#cke_contents_editor iframe')[0];
        this.iDoc = iframe.contentWindow || iframe.contentDocument;

        this.outlineHandlers = new cOutlineHandlers(this.iDoc);

        //click observers
        ////save button
        $('save_button').observe('click', this.save.bind(this));
        ////activate card
        document.observe('click', function(event) {
           if(event.target.hasClassName('card_activation')) this.activateNode(event.target);
        }.bind(this));

    },

    save: function() {

        new Ajax.Request('/create', {
            method: 'post',
            parameters: {'html': this.iDoc.document.getElementsByTagName('body')[0].outerHTML,
                         'name': $('document_name').value},
            onSuccess: function(transport) {
                $('save_return').update(transport.responseText);
            }
        });
    },

    activateNode: function(checkbox) {

        //vars
        var card = checkbox.up('.card');
        var nodeId = doc.utilities.toNodeId(card);
        var node = this.iDoc.document.getElementById(nodeId);

        //activate/dactivate card
        if (checkbox.checked) {
            node.setAttribute('active', true);
            doc.rightRail.cards[nodeId].activate();
        }
        else {
            node.setAttribute('active', false);
            doc.rightRail.cards[nodeId].deactivate();
        }

//        //focus on activated outline node
//        this.focus(nodeId);
    }

//    focus: function(nodeId) {
//
//        console.log(nodeId);
//        var node = doc.outline.iDoc.document.getElementById(nodeId);
//        node.focus();
//    }
});

var cOutlineHandlers = Class.create({

    iDoc: null, //@todo repeated unfortunately - can't access in outline until initialization complete

    initialize: function(iDoc) {
        //capture iframe keystroke events
        this.iDoc = iDoc;
        this.iDoc.document.onkeydown = this.delegateHandler.bind(this);
    },

    delegateHandler: function(event) {

        //get real target - target in event object is wrong
        //@todo this is not quite there - sometimes it returns a ul; also, I
        //      couldn't overwrite event.target
        //@todo target may be be UL or BODY on return key!
        var range, target;
        if (this.iDoc.document.selection) {
            range = this.iDoc.document.selection.createRange();
            target = range.parentElement();
        }
        else if (this.iDoc.window.getSelection) {
            range = this.iDoc.window.getSelection().getRangeAt(0);
            target = range.commonAncestorContainer.parentNode;
        }

        //invoke proper handlers
        switch (event.keyCode) {
            case Event.KEY_TAB:
                this.onTab(event, target);
                break;
            case Event.KEY_RETURN:
                this.onReturn(event, target);
                break;
            case Event.KEY_UP: break;
            case Event.KEY_DOWN: break;
            case Event.KEY_LEFT: break;
            case Event.KEY_RIGHT: break;
            default:
                this.onLetter(event, target);
        }
    },

    onTab: function(event, target) {

        //handle indentation
        if (event.shiftKey) doc.editor.execCommand('outdent');
        else doc.editor.execCommand('indent');
    },

    onReturn: function(event, target) {

        //@todo ajust spec - no need to add attributes until node has content
        //      is this necessary
    },

    onLetter: function(event, target) {

        //get core attributes
        var id = Element.readAttribute(target, 'id') || null;

        //new card
        if (!id) doc.rightRail.createCard(target);

        //existing card
        else if (doc.rightRail.cards[id]) {
            doc.rightRail.cards[id].update(target);
            doc.rightRail.focus(id);
        }

        //error
        else console.log('error: node has id but no card exists')
    }
});

var cRightRail = Class.create({

    cardCount: 0,
    cards: {},
    inFocus: null,

    initialize: function() {},

    createCard: function(node) {

        //check node is valid
        if (   node.tagName.toUpperCase() != 'LI'
            && node.tagName.toUpperCase() != 'P') return;

        this.cards['node_' + this.cardCount] = new cCard(node, this.cardCount)
        this.focus(this.cardCount++);
    },

    focus: function(id) {

        //normalize id
        var cardId = doc.utilities.toCardId(id);
        var nodeId = doc.utilities.toNodeId(id);

        //check card exists
        if (!$(cardId)) {
            console.log("error: can't focus on non-existent card");
            return;
        }

        var rightRail = document.getElementById("right_rail");

        //unfocus previously focused
        if(this.inFocus && this.inFocus.id != cardId) {
            var nodeIdFocused = 'node_' + this.inFocus.id.replace('card_', '');
            Element.removeClassName(this.inFocus, 'card_focus');
            this.cards[doc.utilities.toNodeId(this.inFocus)].render(true);
        }

        this.inFocus = $(cardId);
        Element.addClassName(this.inFocus, 'card_focus');
        rightRail.scrollTop = 
            Element.positionedOffset(this.inFocus)[1];
//            + $('right_rail').getHeight()
//            - Element.getHeight(this.inFocus);
    }
});

var cCard = Class.create({

    cardNumber: null,

    front: '',
    back: '',
    nodeTxt: '',

    active: false,
    elmntCard: null,
    elmntNode: null,
    updating: false,

    autoActivate: false,
    autoActivated: true,    //if auto activated and later format becomes unnacceptable - autoDeactivate

    initialize: function(node, cardCount) {

        //set dom node attributes
        this.cardNumber = cardCount;
        Element.writeAttribute(node, {'id': 'node_' + this.cardNumber,
                                      'changed': new Date().getTime()});
        Element.addClassName(node, 'outline_node');

        //parsing
        node.setAttribute('active', false);
        this._parse(node);

        //card in dom
        var cardHtml = '<div id="card_' + this.cardNumber + '" class="rounded_border card_focus card"></div>';
        this._insert(cardHtml);
        this.elmntCard = $("card_" + this.cardNumber);
        this.render();
    },

    update: function(node) {
        this.elmnt = $(node);
        this.updating = true;

        this._parse(this.elmnt);
        this.render();

        this.updating = false;
    },

    activate: function() {
        this.active = true;
        $('card_' + this.cardNumber).addClassName('card_active');
    },

    deactivate: function() {
        this.active = false;
        $('card_' + this.cardNumber).removeClassName('card_active');
    },

    render: function(truncate) {

        //checkbox
        var checkbox;
        if (this.active == true) checkbox = '<input type="checkbox" class="card_activation" checked="yes" />';
        else checkbox = '<input type="checkbox" class="card_activation" />';

        //truncated txt
        if (truncate && !this.active) {
            this.elmntCard.innerHTML
                = checkbox + this.nodeTxt;
        }

        //both sides set
        else if (this.back) {
            this.elmntCard.innerHTML = '<div class="card_front">'
                    + checkbox + this.front + '</div>\
                <div class="card_back">'+this.back+'</div>';

            //autoActivate
            if (this.autoActivate) {
                this.autoActivated = true;
                this.activate();
                this.autoActivate = false;
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
        else {
            console.log('error: cannot render - no card in dom to update')
            if (this.updating) console.log ('...while updating')
        }

    },

    _insert: function(cardHtml) {
        //identify previous node in outline
        var nodeId = 'node_' + this.cardNumber;
        var outlineNode = doc.outline.iDoc.document.getElementById(nodeId);
        var outlineNodes = doc.outline.iDoc.document.getElementsByClassName('outline_node');
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
            console.log('error: no previous card but there should be! creating...');
            if (this.updating) console.log ('...while updating');

            //create previous card
            console.log(outlineNodePrev);
            //doc.rightRail.createCard(outlineNodePrev);
            console.log('previous card created');

            //temp
            $('cards').insert({bottom: cardHtml});
        }

        //insert later
        else $(cardIdPrev).insert({after: cardHtml});
    },

    _parse: function(node) {

        this.nodeTxt = node.innerHTML.match(/^([^<]*)<?/)[1];
        this.active = node.getAttribute('active') == "true";

        //definition
        var defParts = this.nodeTxt.match(/(^[^-]+) - ([\s\S]+)$/);
        if (defParts) {

            //set autoActivate member if this is the first time text has been parsable
            if (!this.back && !this.active) this.autoActivate = true;

            this.front = defParts[1];
            this.back = defParts[2];
        }

        //fill in the blank
        else if (false) {}

        //no match
        else {
            this.front = this.nodeTxt;
            this.back = '';
        }
    }
});

var cUtilities = Class.create({

    toNodeId: function(mixed) {
        var id = this._getId(mixed);
        if (id) return 'node_' + id;
    },

    toCardId: function(mixed) {
        var id = this._getId(mixed);
        if (id) return 'card_' + id;
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

var doc = new cDoc();