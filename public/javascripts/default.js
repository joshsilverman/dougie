
var cDoc = Class.create({

    initialize: function() {

        /* resize listener */
        window.onresize = AppUtilities.resizeContents;
        AppUtilities.resizeContents();
    }
});

/* global objects */
document.observe('dom:loaded', function() {
    doc = new cDoc();

    /* fire app:loaded */
    document.fire('app:loaded');
});