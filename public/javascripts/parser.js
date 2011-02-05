var cParser = Class.create({

    parse: function(Card, contextualize, ellipsize) {

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
        else if (ellipsize) this.ellipsize(Card);
    },

    contextualize: function(Card) {

        /* set docHtml var */
        //look for document_123 tag
        var docHtml = $('document_' + Card.documentId);

        //or look for ckeditor
        if (!docHtml && doc.outline) {
            docHtml = doc.outline.iDoc.document.body
        }
        if (!docHtml) return;

        docHtml = Element.clone(docHtml, true)
        docHtml.id = '';

        /* locate adjust line node */
        var line = Element.select(docHtml, '#' + Card.domId);
        if (line.length == 0) return;
        line = Element.extend(line[0]);
        Element.update(line, Card.front)

        /* display properties for cue */
        if (line.tagName == 'LI') {

            /* traverse anscestors */
            Element.ancestors(line).each(function(ancestor) {
                if (ancestor.tagName == 'LI') Element.setStyle(ancestor, {'display':'list-item'});
                else Element.setStyle(ancestor, {'display':'block'});});

            /* set line display block/list-item based on exists ancestors */
            if (Element.ancestors(line).length > 2) Element.setStyle(line, {'display':'list-item'});
            else {
                Element.setStyle(line, {'display':'block'});
                Element.setStyle(line, {'display':'block', 'textAlign': 'center'});
            }
        }
        else Element.setStyle(line, {'display':'block', 'textAlign': 'center'});
        Element.addClassName(line, 'card_front_cue')

        /* update front */
        Card.front = docHtml;
    },

    ellipsize: function() {}
});