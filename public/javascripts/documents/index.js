var fDocument = function() {

    var outline = new fOutline();
    var rightRail = new fRightRail();

    var init = function() {}.apply(this, arguments);

    var save = function() {};
};

var fOutline = function() {

    var outlineHandlers = new fOutlineHandlers();

    var init = function() {}.apply(this, arguments)
};

var fOutlineHandlers = function() {

    var init = function() {

        //capture iframe keystroke events
        var iframe = $$('#cke_contents_editor iframe')[0];
        var iDoc = iframe.contentWindow || iframe.contentDocument;
        iDoc.document.onkeyup = delegateHandler.curry(iDoc);

    }.delay(1, arguments); //@todo this creates race condition - look for callback

    var delegateHandler = function(iDoc, event) {

        //get real target - target in event object is wrong
        //@todo this is not quite there - sometimes it returns a ul; also, I
        //      couldn't overwrite event.target
        //@todo target may be be UL or BODY on return key!
        var range, target;
        if (iDoc.document.selection) {
            range = iDoc.document.selection.createRange();
            target = range.parentElement();
        }
        else if (iDoc.window.getSelection) {
            range = iDoc.window.getSelection().getRangeAt(0);
            target = range.commonAncestorContainer.parentNode;
        }

        //invoke proper handlers
        switch (event.keyCode) {
            case Event.KEY_TAB:
                onTab(event, target);
                break;
            case Event.KEY_RETURN:
                onReturn(event, target);
                break;
            default:
                break;
        }
    };

    var onTab = function(event, target) {
        if (event.shiftKey) CKEDITOR.instances.editor.execCommand('outdent');
        else CKEDITOR.instances.editor.execCommand('indent');
    };

    var onReturn = function(event, target) {

        //@todo ajust spec - no need to add attributes until node has content
        //      is this necessary

    };

};

var fRightRail = function() {

    var init = function() {}.apply(this, arguments);

    var cards = [];

    var focus = function() {};

};

fCard = function() {

    var init = function() {}.apply(this, arguments);

    var create = function() {};

    var update = function() {};

    var activate = function() {};

    var deactivate = function() {};
}

var doc = new fDocument('a', 'b');