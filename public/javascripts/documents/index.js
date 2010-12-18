var fDocumentsIndex = function() {

    var outline = new fOutline();
    var rightRail = new fRightRail();

    var init = function() {}.call();
};

var fOutline = function() {

    var outlineHandlers = new fOutlineHandlers();

    var init = function() {}.call();
};

var fOutlineHandlers = function() {

    var init = function() {

        //capture iframe click events
        var iframe = $$('#cke_contents_editor iframe')[0];
        var iDoc = iframe.contentWindow || iframe.contentDocument;
        iDoc.document.onkeydown = delegateHandler.curry(iDoc);

    }.delay(1); //@todo this creates race condition

    var delegateHandler = function(iDoc, event) {

        //override event target - //@todo not quite there but close!
        if (iDoc.document.selection) {
            range = iDoc.document.selection.createRange();
            event.target = range.parentElement();
        }
        else if (iDoc.window.getSelection) {
            var range = iDoc.window.getSelection().getRangeAt(0);
            event.target = range.commonAncestorContainer.parentNode || iDoc.document;
        }

        //invoke proper handlers
        switch (event.keyCode) {
            case Event.KEY_TAB:
                onTab(event);
                break;
            default:
                break;
        }
    };

    var onTab = function(event) {
        if (event.shiftKey) CKEDITOR.instances.editor.execCommand('outdent');
        else CKEDITOR.instances.editor.execCommand('indent');
        Event.stop(event);
    };

};

var fRightRail = function() {

    var init = function() {}.call();

    var cards = [];
};


var documentsIndex = new fDocumentsIndex();