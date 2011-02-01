var cParser = Class.create({

    parse: function(Card, contextualize) {

        //definition
        var defParts = Card.text.match(/(^[\w\W]+) - ([\s\S]+)$/);
        if (defParts) {

            //set autoActivate member if this is the first time text has been parsable
            if (!Card.back && !Card.active) Card.autoActivate = true;

            Card.front = defParts[1];
            Card.back = defParts[2];
        }

        //fill in the blank
        else if (false) {}

        //no match
        else {
            Card.front = Card.text;
            Card.back = '';
        }

        /* set simpleFront on card before attempting to contextualize*/
        Card.simpleFront = Card.front;
        
        /* add context to front if showContext set to true */
        if (contextualize) this.contextualize(Card);
    },

    contextualize: function(Card) {

        /* set doc var */
        var doc = $('document_' + Card.documentId);
        if (!doc) return;
        doc = doc.clone(true)
        doc.id = '';

        /* locate adjust line node */
        var line = Element.select(doc, '#' + Card.domId);
        if (line.length == 0) return;
        line = line[0];
        line.update(Card.front)

        /* display properties for cue */
        if (line.tagName == 'LI') {

            /* traverse anscestors */
            line.ancestors().each(function(ancestor) {
            if (ancestor.tagName == 'LI') ancestor.setStyle({'display':'list-item'});
            else ancestor.setStyle({'display':'block'});});

            /* set line display block/list-item based on exists ancestors */
            if (line.ancestors().length > 0) line.setStyle({'display':'list-item'});
            else {
                line.setStyle({'display':'block'});
                line.setStyle({'display':'block', 'textAlign': 'center'});
            }
        }
        else line.setStyle({'display':'block', 'textAlign': 'center'});
        line.addClassName('card_front_cue')
        
        /* update front */
        Card.front = doc.clone(true);
    }
});