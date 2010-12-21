var cDoc = Class.create({

    outline: null,
    rightRail: null,
    editor: null,

    initialize: function() {

        //wait for ckeditor to load
        document.observe('CKEDITOR:ready', function() {
            this.editor = CKEDITOR.instances.editor;
            this.rightRail = new cRightRail();

            //@todo this creates race condition - look for callback - ugglie!!!
            (function () {this.outline = new cOutline();}.bind(this)).delay(.1);

        }.bind(this));
    },

    save: function() {}
});

var cOutline = Class.create({

    outlineHandlers: null,

    initialize: function() {
        this.outlineHandlers = new cOutlineHandlers();
    }
});

var cOutlineHandlers = Class.create({

    iDoc: null,

    initialize: function() {

        //capture iframe keystroke events
        var iframe = $$('#cke_contents_editor iframe')[0];
        this.iDoc = iframe.contentWindow || iframe.contentDocument;
        this.iDoc.document.onkeyup = this.delegateHandler.bind(this);

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
        else doc.rightRail.cards[id].update(target);
    }
});

var cRightRail = Class.create({

    cardCount: 0,
    cards: {},
    inFocus: null,

    initialize: function() {},

    createCard: function(node) {
        this.cards['node_' + this.cardCount] = new cCard(node, this.cardCount)
        this.focus('card_' + this.cardCount++);
    },

    focus: function(id) {
        var rightRail = document.getElementById("right_rail");

        Element.removeClassName(this.inFocus, 'card_focus')
        this.inFocus = document.getElementById(id);

        rightRail.scrollTop = Element.positionedOffset(this.inFocus)[1];
    }
});

var cCard = Class.create({

    cardNumber: null,
    front: '',
    back: '',
    active: false,
    elmnt: null,

    initialize: function(node, cardCount) {

        //set dom node attributes
        this.cardNumber = cardCount;
        Element.writeAttribute(node, {'id': 'node_' + this.cardNumber,
                                      'changed': new Date().getTime()});

        //parsing
        this._parse(node);

        //card in dom
        var cardHtml = '<div id="card_' + this.cardNumber + '" class="card_focus card"></div>';
        $('cards').insert({bottom: cardHtml}); //@todo insert in proper location
        this.elmnt = document.getElementById("card_" + this.cardNumber);
        this._render();
    },

    update: function(node) {
        
        this._parse(node);
        this._render();
        
    },

    activate: function() {},

    deactivate: function() {},

    _render: function() {

        //both sides set
        if (this.back) {
            var cardFaces = '<div class="card_front">'+this.front+'</div>\
                <div class="card_back">'+this.back+'</div>';
        }

        //just front
        else {
            var cardFaces = '<div class="card_front">'+this.front+'</div>';
        }

        //set
        this.elmnt.innerHTML = cardFaces;

    },

    _parse: function(node) {

        var nodeTxt = node.innerHTML;

        //definition
        var defParts = nodeTxt.match(/(^[^-]+) - ([\s\S]+)$/);
        if (defParts) {
            this.front = defParts[1];
            this.back = defParts[2];
        }

        //fill in the blank
        else if (false) {}

        //no match
        else this.front = nodeTxt;
    }
    
});

var doc = new cDoc();