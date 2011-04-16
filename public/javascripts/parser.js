var cParser = Class.create({

    docHTML: null,
    line:null,

    parse: function(Card, contextualize, ellipsize) {

        //pull card text from doc if text is blank
        if (Card.text == null) this._identifyDoc(Card);
        if (Card.text == null) Card.text = "";

        var defParts = Card.text.split(/(?:\s+-+\s+|-+\s+|\s+-+)/);

        if (defParts.length > 1) {

            //set autoActivate member if this is the first time text has been parsable
            if (!Card.back && !Card.active) Card.autoActivate = true;

            Card.front = defParts[0];
            Card.back = defParts.slice(1).join(' - ').unescapeHTML();
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
        if (contextualize) this._contextualize(Card);
        else if (ellipsize) this._ellipsize(Card);
    },

    _contextualize: function(Card) {

        /* identify doc and line */
        this._identifyDoc(Card);

        /* display properties for cue */
        if (!this.line) {
            console.log(Card);
            console.log(this.line);
            return
        }
        if (this.line.tagName == 'LI') {

            /* traverse anscestors */
            Element.ancestors(this.line).each(function(ancestor) {
                if (ancestor.tagName == 'LI') Element.setStyle(ancestor, {'display':'list-item'});
                else Element.setStyle(ancestor, {'display':'block'});});

            /* set line display block/list-item based on exists ancestors */
            if (Element.ancestors(this.line).length > 2) Element.setStyle(this.line, {'display':'list-item'});
            else {
                Element.setStyle(this.line, {'display':'block'});
                Element.setStyle(this.line, {'display':'block', 'textAlign': 'center'});
            }

            Card.front = this.docHtml;
        }
        else {
            Element.setStyle(this.line, {'display':'block', 'textAlign': 'center'});
            Card.front = this.line;
        }
        Element.addClassName(this.line, 'card_front_cue')
    },

    _ellipsize: function(Card) {

        /* identify doc and line */
        this._identifyDoc(Card);
        if (this.line.tagName == 'LI') Card.front = this.line;
        var grandparent = Element.up(Element.up(this.line));
        if (grandparent && grandparent.tagName == 'LI')
            Card.front = "<ul style='text-align:left; color:#666;'><li>...<ul><li style='color:black;'>"+Card.front.innerHTML+"</li><ul></li></ul>"

    },

    _identifyDoc: function(Card) {

        /* set docHtml var */
        //look for document_123 tag
        this.docHtml = $('document_' + Card.documentId);

        //or look for ckeditor
        if (!this.docHtml && window['doc'] && doc.outline) {
            this.docHtml = doc.outline.iDoc.body
        }
        if (!this.docHtml) return;

        this.docHtml = Element.clone(this.docHtml, true)
        this.docHtml.id = '';

        /* locate adjust line node */
        this.line = Element.select(this.docHtml, '#' + Card.domId);
        if (this.line.length == 0) return;
        Card.text = this.line[0].innerHTML.split(/<(?:li|ul|p)/)[0];
        this.line = Element.extend(this.line[0]);
        Element.update(this.line, Card.front);
    }
});