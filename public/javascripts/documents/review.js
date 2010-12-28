var cDoc = Class.create({

    reviewer: null,
    progressBar: null,

    initialize: function() {

        /* new reviewer */
        var data = $('card_json').innerHTML.evalJSON();
        this.reviewer = new cReviewer(data);
    }
});

var cReviewer = Class.create({

    cards: [],
    currentCardIndex: 0,

    initialize: function(data) {

        /* load cards */
        $H(data).each(function(cardData, index) {
            this.cards.push(new cCard(cardData[1]));
        }.bind(this));

        /* show first card and next listener*/
        this.cards[0].showFront();
        $('card_next').observe('click', this.cards[0].showAll.bind(this.cards[0]));
    }
});

var cCard = Class.create({

    GRADE_KNOW: 4,
    GRADE_MUSTLEARN: 3,
    GRADE_KNOWBUT: 2,
    GRADE_DONTCARE: 1,

    lineId: null,
    text: '',
    front: '',
    back: '',

    grade: null,
    
    initialize: function(data) {

        this.id = data.id;
        this.text = data.text;
        parser.parse(this);
    },

    showFront: function() {
        $('card_front').update(this.front);
    },

    showAll: function() {
        $('card_front').update(this.front);
        $('card_back').update(this.back);
    },

    grade: function() {

        this._save()
    },

    _save: function() {

    }
    
});

var cProgressBar = Class.create({

    update: function(progress) {

    }
});

/* global objects */
document.observe('dom:loaded', function() {
    parser = new cParser();
    doc = new cDoc();
});