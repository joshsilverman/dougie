/* class declarations */

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
        data.each(function(cardData) {
            this.cards.push(new cCard(cardData['line']));
        }.bind(this));

        /* show first */
        this.cards[0].cue();
        
        /* next listeners */
        $('strength_1').observe('click', this.next.bind(this, 1));
        $('strength_2').observe('click', this.next.bind(this, 2));
        $('strength_3').observe('click', this.next.bind(this, 3));
        $('strength_4').observe('click', this.next.bind(this, 4));
    },

    next: function(grade) {

        /* grade current */
        this.cards[this.currentCardIndex].grade(grade);

        /* advance */
        if (this.cards[this.currentCardIndex + 1]) {
            this.currentCardIndex++;
            this.cards[this.currentCardIndex].cue();
        }
        else alert('No more cards for this document');
    }
});

var cCard = Class.create({

    GRADE_KNOW: 4,
    GRADE_MUSTLEARN: 3,
    GRADE_KNOWBUT: 2,
    GRADE_DONTCARE: 1,

    /* out of ten for easy url  */
    importance: 5,
    confidence: 5,

    memId: null,
    lineId: null,
    text: '',
    front: '',
    back: '',
    
    initialize: function(data) {

        this.lineId = data['id'];
        this.memId = data['mems'][0]['id'];
        this.documentId = data['document_id'];
        this.text = data['text'];
        parser.parse(this);
    },

    cue: function() {

        /* cue cards */
        $('card_front').update(this.front);
        $('card_back').update('<button id="card_show">Show</button>');
        $('card_show').observe('click', this.showAll.bind(this));

        /* hide grade buttons */
        $$('.grade').each(function (td) {td.addClassName('grade_hide')});
    },

    showAll: function() {

        /* show both sides */
        $('card_front').update(this.front);
        $('card_back').update(this.back);

        /* show grading buttons */
        $$('.grade').each(function (td) {td.removeClassName('grade_hide')});
    },

    grade: function(grade) {

        switch (grade) {
            case this.GRADE_KNOW:
                this.confidence = 8;
                this.importance = 8;
                break;
            case this.GRADE_MUSTLEARN:
                this.confidence = 2;
                this.importance = 8;
                break;
            case this.GRADE_KNOWBUT:
                this.confidence = 8;
                this.importance = 2;
                break;
            case this.GRADE_DONTCARE:
                this.confidence = 2;
                this.importance = 2;
                break;
        }

        this._save()
    },

    _save: function() {

        var requestUrl = '/mems/update/'+this.memId+'/'+this.confidence+'/'+this.importance;
        new Ajax.Request(requestUrl, {
            onSuccess: function() {},
            onFailure: function() {},
            onComplete: function(transport) {
                $('log').update(transport.responseText);
            }
        });
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