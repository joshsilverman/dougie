var cParser = Class.create({

    parse: function(Card) {

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
    }
});