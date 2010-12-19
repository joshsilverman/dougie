var cDoc = Class.create({

    outline: null,
    rightRail: null,
    editor: null,

    initialize: function() {

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
                break;
        }
    },

    onTab: function(event, target) {
        if (event.shiftKey) doc.editor.execCommand('outdent');
        else doc.editor.execCommand('indent');
    },

    onReturn: function(event, target) {

        //@todo ajust spec - no need to add attributes until node has content
        //      is this necessary

    }

});

var cRightRail = Class.create({

    initialize: function() {},

    cards: {},

    focus: function() {}
});

var cCard = Class.create({

    initialize: function() {},

    render: function() {},

    create: function() {},

    update: function() {},

    activate: function() {},

    deactivate: function() {}
});

var doc = new cDoc();