var cDoc = function() {

    this.outline;
    this.rightRail;
    this.editor;

    this.init = function() {

        document.observe('CKEDITOR:ready', function() {

            this.editor = CKEDITOR.instances.editor;
            this.outline = new cOutline();
            this.rightRail = new cRightRail();

        }.bind(this));
    }.apply(this, arguments);

    this.save = function() {};
};

var cOutline = function() {

    this.outlineHandlers = new cOutlineHandlers();

    this.init = function() {}.apply(this, arguments)
};

var cOutlineHandlers = function() {

    this.iDoc;

    this.init = function() {

        //capture iframe keystroke events
        var iframe = $$('#cke_contents_editor iframe')[0];
        this.iDoc = iframe.contentWindow || iframe.contentDocument;
        this.iDoc.document.onkeyup = this.delegateHandler;

    }.bind(this).delay(.1, arguments); //@todo this creates race condition - look for callback

    this.delegateHandler = function(event) {

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
    }.bind(this);

    this.onTab = function(event, target) {
        if (event.shiftKey) doc.editor.execCommand('outdent');
        else doc.editor.execCommand('indent');
    };

    this.onReturn = function(event, target) {

        //@todo ajust spec - no need to add attributes until node has content
        //      is this necessary

    };

};

var cRightRail = function() {

    this.init = function() {}.apply(this, arguments);

    this.cards = {};

    this.focus = function() {};

};

var cCard = function() {

    this.init = function() {}.apply(this, arguments);

    this.render = function() {};

    this.create = function() {};

    this.update = function() {};

    this.activate = function() {};

    this.deactivate = function() {};
}

var doc = new cDoc();