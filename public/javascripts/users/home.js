
var cDoc = Class.create({

    restoreDefaultTimer: null,

    mouseoverTargets: $H({
       'notes': '<h1><span style=\'color:#009CFF;\'>Learn</span> by taking notes as usual</h1><h5>We\'ll turn it into study material for you!</h5>',
       'flashcards': '<h1><span style=\'color:#009CFF;\'>Study</span> using flashcards made from your notes</h1><h5>We\'ll track what\'s important to you and how well you know it!</h5>',
       'review': '<h1><span style=\'color:#009CFF;\'>Know</span> all of your material cold</h1><h5>Study what matters at the right time for improved retention in less time!</h5>'
    }),

    defaultMessage: null,

    initialize:function() {

        /* store current value of headline */
        this.defaultMessage = document.getElementById('headline').innerHTML;

        /* splash listeners */
        this.mouseoverTargets.each(function(keyValue) {

            var src = '/images/home/' + keyValue[0] + '.png'
            var srcUnderlined = '/images/home/' + keyValue[0] + '_underline.png'

            /* over */
            $('img_' + keyValue[0]).observe('mouseover', function(event) {

                /* make sure all are not underlined */
                this.mouseoverTargets.each(function(keyValue) {
                    $('img_' + keyValue[0]).src = '/images/home/' + keyValue[0] + '.png';
                });

                event.target.src = srcUnderlined;
                window.clearTimeout(this.restoreDefaultTimer);
                document.getElementById('headline').innerHTML = keyValue[1];
            }.bind(this));

            /* out */
            $('img_' + keyValue[0]).observe('mouseout', function(event) {
                this.restoreDefaultTimer
                    = this.restoreDefault.bind(this).delay(.75, event.target, src);
            }.bind(this));
        }.bind(this));

//        /* load light view */
//        this.loadLightview();
    },

    restoreDefault: function(target, src) {
        target.src = src;
        document.getElementById('headline').innerHTML
            = this.defaultMessage;
    }

//    loadLightview: function() {
//
//        var script = new Element('script', {'type': 'text/javascript', 'src': "/javascripts/vendors/lightview/js/lightview.js"});
//        var container = document.getElementById("script_lightview");
//        if (container) container.appendChild(script);
//        console.log(script);
//    }
});

/* global objects */
document.observe('dom:loaded', function() {
    doc = new cDoc;

    /* fire app:loaded */
    document.fire('app:loaded');
});