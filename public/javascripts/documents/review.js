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

    progressBar: null,

    cards: [],
    currentCardIndex: 0,

    initialize: function(data) {

        /* load cards */
        data.each(function(cardData) {
            this.cards.push(new cCard(cardData['line']));
        }.bind(this));

        /* show first */
        if (this.cards[0]) this.cards[0].cue();
        else $('card_front').update("<i>No cards to review</i>");
        
        /* next listeners */
        $('strength_1').observe('click', this.next.bind(this, 1));
        $('strength_2').observe('click', this.next.bind(this, 2));
        $('strength_3').observe('click', this.next.bind(this, 3));
        $('strength_4').observe('click', this.next.bind(this, 4));

        /* nav listeners */
        $('back_button').observe('click', this.back.bind(this, false));
        $('next_button').observe('click', this.next.bind(this, false));

        /* progress bar */
        this.progressBar = new cProgressBar();
        $('progress_fraction').update("0/"+this.cards.length);
    },

    next: function(grade) {

        /* grade current */
        if (grade) this.cards[this.currentCardIndex].grade(grade);
        this.currentCardIndex++;

        /* advance */
        if (this.cards[this.currentCardIndex]) {
            this.cards[this.currentCardIndex].cue();
        }
        else alert('No more cards for this document');

        /* update progress bar */
        this.progressBar.update((this.currentCardIndex)/this.cards.length);
        $('progress_fraction').update(this.currentCardIndex+"/"+this.cards.length);
    },

    back: function(grade) {

        /* back */
        this.currentCardIndex--;
        if (this.cards[this.currentCardIndex]) {
            this.cards[this.currentCardIndex].cue();
        }

        /* update progress bar */
        this.progressBar.update((this.currentCardIndex)/this.cards.length);
        $('progress_fraction').update(this.currentCardIndex+"/"+this.cards.length);
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

    buttons: '<div id="edit_buttons">\
                <button id="button_edit" class="edit" style="display:none">Edit</button>\
                <button id="button_done" class="done" style="display:none">Done</button>\
                <button id="button_cancel" class="cancel" style="display:none">X</button>\
              </div>',
    
    initialize: function(data) {

        this.lineId = data['id'];
        this.memId = data['mems'][0]['id'];
        this.documentId = data['document_id'];
        this.text = data['text'];
        parser.parse(this);
    },

    cue: function() {

        /* front */
        $('card_front').update("<div id='card_front_text'>"+this.front+"</div>" + this.buttons);

        /* back */
        $('card_back').update('<button id="card_show">Show</button>');
        $('card_show').observe('click', this.showAll.bind(this));

        /* hide grade buttons */
        $$('.grade').each(function (td) {td.addClassName('grade_hide')});
    },

    showAll: function() {

        /* show */
        $('card_front').update("<div id='card_front_text'>"+this.front+"</div>" + this.buttons);
        $('card_back').update( "<div id='card_back_text'>"+this.back+"</div>");

        /* show grading buttons */
        $$('.grade').each(function (td) {td.removeClassName('grade_hide')});

        /* edit button and listener */
        $('button_edit').observe('click', this.makeEditable.bind(this));
        $('button_edit').show();
    },

    grade: function(grade) {

        /* set confidence and importance */
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

            /* catch if not a grade - ie person has pressed next button */
            default:
                return;
                break;
        }

        /* save grade */
        var requestUrl = '/mems/update/'+this.memId+'/'+this.confidence+'/'+this.importance;
        new Ajax.Request(requestUrl, {
            onSuccess: function() {},
            
            onFailure: function() {},

            onComplete: function(transport) {$('log').update(transport.responseText);}
        });
    },

    makeEditable: function() {

        /* buttons */
        $('button_done').show();
        $('button_cancel').show();
        $('button_edit').hide();

        /* inputs */

        //front
        var input = "<textarea id='input_front'>"+this.front+"</textarea>";
        $('card_front_text').remove();
        $('edit_buttons').insert({'after': input});
        $('input_front').focus();

        //back
        var input = "<textarea id='input_back'>"+this.back+"</textarea>";
        $('card_back_text').remove();
        $('card_back').update(input);

        /* listeners */
        $('button_done').observe('click', this.update.bind(this));
        $('button_cancel').observe('click', this.showAll.bind(this));
    },

    update: function() {

        /* text */
        var text = $('input_front').value + ' - ' + $('input_back').value;

        /* save */
        var requestUrl = '/lines/'+this.lineId;
        new Ajax.Request(requestUrl, {
            method: 'put',
            parameters: {"line[text]": text, "line[id]": this.lineId},
            
            onSuccess: function(transport) {

                /* reparse and update card */
                var data = transport.responseText.evalJSON();
                this.text = data['line']['text'];
                parser.parse(this);
            }.bind(this),

            onFailure: function() {},

            onComplete: function(transport) {this.showAll();}.bind(this)
        });
    }
});

var cProgressBar = Class.create({

    bramus: null,
    bramusBrogressBar: null,

    initialize: function() {

        /* bramus instance and set progress instance */
        this.bramus = new JS_BRAMUS.jsProgressBarHandler();
        this.bramusBrogressBar = new JS_BRAMUS.jsProgressBar( $('progress_bar'), 0, {
            showText	: false,
            width	: 154,
            height	: 11,
            boxImage	: '/images/progressbar/custom1_box.gif',
            barImage	: '/images/progressbar/custom1_bar.gif'});
    },

    update: function(progress) {

        var percentage = Math.round(progress * 100);
        this.bramusBrogressBar.setPercentage(percentage);
    }
});

/* global objects */
document.observe('dom:loaded', function() {
    parser = new cParser(); //@todo move to doc object
    doc = new cDoc();
});