
var cDoc = Class.create({

    mouseoverTargets: $H({
       'learn': '<h1><span style=\'color:#009CFF;\'>Learn</span> by taking notes as usual</h1><h5>We\'ll turn it into study material for you!</h5>',
       'study': '<h1><span style=\'color:#009CFF;\'>Study</span> using flashcards made from your notes</h1><h5>We\'ll track what\'s important to you and how well you know it!</h5>',
       'know': '<h1><span style=\'color:#009CFF;\'>Know</span> all of your material cold</h1><h5>Study what matters at the right time for improved retention in less time!</h5>'
    }),

    initialize:function() {

        /* splash listeners */
        this.mouseoverTargets.each(function(keyValue) {

            var src = '/images/home/' + keyValue[0] + '.png'
            var srcUnderlined = '/images/home/' + keyValue[0] + '_underline.png'

            /* over */
            $('img_' + keyValue[0]).observe('mouseover', function(event) {
                event.target.src = srcUnderlined;
                document.getElementById('headline').innerHTML = keyValue[1];
            }.bind(this));

            /* out */
            $('img_' + keyValue[0]).observe('mouseout', function(event) {event.target.src = src;}.bind(this));
         });
    }
});

/* global objects */
document.observe('dom:loaded', function() {
    doc = new cDoc;
});