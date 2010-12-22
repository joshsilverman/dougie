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

        $('save_button').observe('click', this.save.bind(this));
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
    }
});

var cOutlineHandlers = Class.create({

    iDoc: null, //@todo repeated unfortunately - can't access in outline until initialization complete

    initialize: function(iDoc) {
        //capture iframe keystroke events
        this.iDoc = iDoc;
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
        if (!Object.isNumber(id)) {
            id = id.replace('card_', '');
            id = id.replace('node_', '');
        }
        var cardId = "card_" + id;
        var nodeId = "node_" + id;

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
            this.inFocus.innerHTML
                = doc.outline.iDoc.document.getElementById(nodeIdFocused)
                  .innerHTML.match(/^([^<]*)<?/)[1];
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
    active: false,
    elmntCard: null,
    elmntNode: null,
    updating: false,

    initialize: function(node, cardCount) {

        //set dom node attributes
        this.cardNumber = cardCount;
        Element.writeAttribute(node, {'id': 'node_' + this.cardNumber,
                                      'changed': new Date().getTime()});
        Element.addClassName(node, 'outline_node');


        //parsing
        this._parse(node);

        //card in dom
        var cardHtml = '<div id="card_' + this.cardNumber + '" class="rounded_border card_focus card"></div>';
        this._insert(cardHtml);
        this.elmntCard = document.getElementById("card_" + this.cardNumber);
        this._render();
    },

    update: function(node) {
        this.updating = true;

        this._parse(node);
        this._render();

        this.updating = false;
    },

    activate: function() {},

    deactivate: function() {},

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
        if (!cardIdPrev) $('cards').insert({bottom: cardHtml});

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

    _render: function() {
        //both sides set
        if (this.back) {
            this.elmntCard.innerHTML = '<div class="card_front">'+this.front+'</div>\
                <div class="card_back">'+this.back+'</div>';
        }

        //just front
        else if (this.elmntCard)
            this.elmntCard.innerHTML = '<div class="card_front">'+this.front+'</div>';

        //no card to update
        else {
            console.log('error: cannot render - no card in dom to update')
            if (this.updating) console.log ('...while updating')
        }

    },

    _parse: function(node) {

        var nodeTxt = node.innerHTML.match(/^([^<]*)<?/)[1];

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