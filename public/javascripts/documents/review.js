/* class declarations */

var cDoc = Class.create({

    reviewer: null,
    progressBar: null,

    initialize: function() {

        /* new reviewer */
        var data = $('card_json').innerHTML.evalJSON();
        this.reviewer = new cReviewer(data);

        /* resize listener - fire after dom:loaded */
        window.onresize = this.onResize;
        this.onResize();
        AppUtilities.resizeContents.delay(.01);
    },

    onResize: function() {

        /* vertically center cards */
        var footer = $$('.footer')[0];
        var footerY = footer.getHeight();
        var viewportY = document.viewport.getHeight();
        var title = $('title');
        var titleY = title.getHeight();
        var titlerOffsetY = title.cumulativeOffset()[1];

        var maxContentsY = viewportY - titlerOffsetY - footerY;
        var extraY = maxContentsY - 502;

        var titleMargin = extraY / 2;
        if (titleMargin > 0) $('title').setStyle({'marginTop': titleMargin + 'px'})

        /* place footer */
        AppUtilities.resizeContents();
    }
});

var cReviewer = Class.create({

    progressBar: null,
    reviewHandlers: null,

    grade_4: 9,
    grade_3: 6.5,
    grade_2: 4,
    grade_1: 1.5,

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
        $('grade_4').observe('click', this.next.bind(this, this.grade_4));
        $('grade_3').observe('click', this.next.bind(this, this.grade_3));
        $('grade_2').observe('click', this.next.bind(this, this.grade_2));
        $('grade_1').observe('click', this.next.bind(this, this.grade_1));

        /* nav listeners */
        $('back_button').observe('click', this.back.bind(this, false));
        $('next_button').observe('click', this.next.bind(this, false));

        /* review handlers */
        this.reviewHandlers = new cReviewHandlers();

        /* progress bar */
        this.progressBar = new cProgressBar();
        $('progress_fraction').update("0/"+this.cards.length);
    },

    next: function(grade) {

		//To do:
		//   Prevent counter from augmenting on right arrow after completion.
        /* grade current */
        if (grade) this.cards[this.currentCardIndex].grade(grade);
        this.currentCardIndex++;

        /* advance */
        if (this.cards[this.currentCardIndex]) {
            if (this.cards[this.currentCardIndex].confidence == -1)
                this.cards[this.currentCardIndex].cue();
            else this.cards[this.currentCardIndex].showAll();
        }

        else {
        
            //Set grade values here (got it: count, kinda: count, etc..)
            var gradeHash = $H({9: 0, 6.5: 0, 4: 0, 1.5: 0});

            var score = 0;
            
            //Collect confidence of each card.
            this.cards.each( function(card) {
            	//Skips ungraded cards.
            	if (card.confidence > 0) {
                	gradeHash.set(card.confidence, (gradeHash.get(card.confidence) + 1));
                	score = score + card.confidence;
            	}
            });
			
			//Prevent chart page when no cards were reviews
			if (score <= 0) {
			
				alert("No more cards to review!");
				
			} else {
			
            	//Largest value in hash times # of cards
            	var total = 9 * this.cards.length;
            	var chartURL = "http://chart.apis.google.com/chart?chs=500x225&cht=p3&chco=16BE16|7FE97F|FD6666|E03838&chd=t:"
                	+ gradeHash.get(9) + "," + gradeHash.get(6.5) + "," + gradeHash.get(4) + "," + gradeHash.get(1.5) + 
                	"&chdl=Got%20it+-+" + gradeHash.get(9) + "|Kinda+-+" + gradeHash.get(6.5) +
                	"|Barely+-+" + gradeHash.get(4) + "|No%20clue+-+" + gradeHash.get(1.5) + "&chma=|2"

            	//Hide graphical elements.
            	//$('grade_a').hide();
            	//$('grade_b').hide();
            	//$('grade_c').hide();
            	//$('grade_d').hide();
            	//$('grade_f').hide();
            	//$('progress_fraction').hide();
            	//$$('.arrows_up_down')[0].hide();
            	$('card_front').update("Your score: <h1>" + Math.round((score/total)*100) + "%</h1>");
            	$('card_back').update("<img src=" + chartURL + "></img>");			
			
			}			

        }

        /* update progress bar */
        if (this.currentCardIndex <= this.cards.length) {
        
        	this.progressBar.update((this.currentCardIndex)/this.cards.length);
        	$('progress_fraction').update(this.currentCardIndex+"/"+this.cards.length);
        	
        }
       
    },

    back: function() {

        /* check boundary */
        if (this.currentCardIndex == 0) return;

        /* back */
        this.currentCardIndex--;
        if (this.cards[this.currentCardIndex]) {
            if (this.cards[this.currentCardIndex].confidence == -1) 
                this.cards[this.currentCardIndex].cue();
            else this.cards[this.currentCardIndex].showAll();
        }

        /* update progress bar */
        this.progressBar.update((this.currentCardIndex)/this.cards.length);
        $('progress_fraction').update(this.currentCardIndex+"/"+this.cards.length);
    },

    displayGrade: function(grade) {

        /* remove all chosen classnames */
        $$(".grade button").each(function(element) {
            element.removeClassName('chosen');
        })

        /* display grade */
        if (grade == this.grade_4) $("grade_4").addClassName("chosen");
        else if (grade == this.grade_3) $("grade_3").addClassName("chosen");
        else if (grade == this.grade_2) $("grade_2").addClassName("chosen");
        else if (grade == this.grade_1) $("grade_1").addClassName("chosen");
    }
});

var cReviewHandlers = Class.create({

    initialize: function() {
        console.log("rh init");
        document.observe("keydown", this.delegateKeystrokeHandler.bind(this));
    },

    delegateKeystrokeHandler: function(event) {

        switch (event.keyCode) {
//            case (13):
//                this.onEnter(event);
//                break;
            case (32):
                this.onSpace(event);
                break;
            case (37):
                this.onLeft(event);
                break;
//            case (38):
//                this.onUp(event);
//                break;
            case (39):
                this.onRight(event);
                break;
//            case (40):
//                this.onDown(event);
//                break;
            case (52):
                this.on4(event);
                break;
            case (51):
                this.on3(event);
                break;
            case (50):
                this.on2(event);
                break;
            case (49):
                this.on1(event);
                break;

            default:
                console.log(event.keyCode);
        }
    },

    onSpace: function(event) {
        /* show card sides */
        doc.reviewer.cards[doc.reviewer.currentCardIndex].showAll();
        event.stop();
    },

    onLeft: function(event) {

        //added to enable back key after completion
        //$('card_back').show();
        //$('grade_a').show();
        //$('grade_b').show();
        //$('grade_c').show();
        //$('grade_d').show();
        //$('grade_f').show();


        doc.reviewer.back();
        event.stop();
    },

    onRight: function(event) {
        doc.reviewer.next();
        event.stop();
    },

    onUp: function(event) {

        /* increment current card's grade and display */
        var card = doc.reviewer.cards[doc.reviewer.currentCardIndex];
        card.increment();
        doc.reviewer.displayGrade(card.confidence);
        event.stop();
    },

    onDown: function(event) {

        /* decrement current card's grade and display */
        var card = doc.reviewer.cards[doc.reviewer.currentCardIndex];
        card.decrement();
        doc.reviewer.displayGrade(card.confidence);
        event.stop();
    },

    onEnter: function() {

        /* invoke next with current card's confidence */
        doc.reviewer.next(doc.reviewer.cards[doc.reviewer.currentCardIndex].confidence);
    },

    on4: function() {
        $$('.button_container, .grade_yourself').each(function (buttonContainer) {buttonContainer.addClassName('grade_hide')});
        doc.reviewer.displayGrade(doc.reviewer.grade_4);
        doc.reviewer.next.bind(doc.reviewer).delay(.4, doc.reviewer.grade_4)
    },

    on3: function() {
        $$('.button_container, .grade_yourself').each(function (buttonContainer) {buttonContainer.addClassName('grade_hide')});
        doc.reviewer.displayGrade(doc.reviewer.grade_3);
        doc.reviewer.next.bind(doc.reviewer).delay(.4, doc.reviewer.grade_3)
    },

    on2: function() {
        $$('.button_container, .grade_yourself').each(function (buttonContainer) {buttonContainer.addClassName('grade_hide')});
        doc.reviewer.displayGrade(doc.reviewer.grade_2);
        doc.reviewer.next.bind(doc.reviewer).delay(.4, doc.reviewer.grade_2)
    },

    on1: function() {
        $$('.button_container, .grade_yourself').each(function (buttonContainer) {buttonContainer.addClassName('grade_hide')});
        doc.reviewer.displayGrade(doc.reviewer.grade_1);
        doc.reviewer.next.bind(doc.reviewer).delay(.4, doc.reviewer.grade_1)
    }
});

var cCard = Class.create({

    /* out of ten for easy url  */
    importance: 8,
    confidence: -1,
    memId: null,
    lineId: null,
    domId: null,
    documentId: null,
    text: '',
    front: '',
    simpleFront: '',
    back: '',

    buttons: '<div id="edit_buttons">\
                <button id="button_edit" class="edit" style="display:none">Edit</button>\
                <button id="button_done" class="done" style="display:none">Done</button>\
                <button id="button_cancel" class="cancel" style="display:none">X</button>\
              </div>',
    
    initialize: function(data) {

        this.lineId = data['id'];
        this.domId = data['domid'];
        this.memId = data['mems'][0]['id'];
        this.documentId = data['document_id'];
        this.text = data['text'];
    },

    cue: function() {

        /* parse on demand - to avoid latency on initializing reviewer */
        parser.parse(this, true);

        /* front */
        $('card_front').update("<div id='card_front_text'>"+this.front+"</div>" + this.buttons);
        $('card_front_text').update(this.front);

        /* back */
        $('card_back').update('<button id="card_show">Show (space bar)</button>');
        $('card_show').observe('click', this.showAll.bind(this));

        /* hide grade buttons */
        $$('.button_container, .grade_yourself').each(function (buttonContainer) {buttonContainer.addClassName('grade_hide')});
//        $$('.arrows_up_down')[0].hide();
    },

    showAll: function() {

        /* show */
        $('card_front').update("<div id='card_front_text'></div>" + this.buttons);
        $('card_front_text').update(this.front);
        $('card_back').update( "<div id='card_back_text'>"+this.back+"</div>");

        /* show grading buttons */
        $$('.button_container, .grade_yourself').each(function (buttonContainer) {buttonContainer.removeClassName('grade_hide')});
//        $$('.arrows_up_down')[0].show();

        /* set grade associated with current card */
        doc.reviewer.displayGrade(doc.reviewer.cards[doc.reviewer.currentCardIndex].confidence);

        /* edit button and listener */
        $('button_edit').observe('click', this.makeEditable.bind(this));
        $('button_edit').show();
    },

    grade: function(grade) {

        /* set confidence */
        this.confidence = grade

        /* save grade */
        var requestUrl = '/mems/update/'+this.memId+'/'+this.confidence+'/'+this.importance;
        new Ajax.Request(requestUrl, {
            onSuccess: function() {},
            
            onFailure: function() {},

            onComplete: function(transport) {}//$('log').update(transport.responseText);}
        });
    },

    makeEditable: function() {

        /* buttons */
        $('button_done').show();
        $('button_cancel').show();
        $('button_edit').hide();

        /* inputs */

        //front
        var input = "<textarea id='input_front'>"+this.simpleFront+"</textarea>";
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
                this.text = data['line'];
                $('document_' + this.documentId).update(data['html']);
                parser.parse(this, true);
            }.bind(this),

            onFailure: function() {},

            onComplete: function(transport) {this.showAll();}.bind(this)
        });
    },

    increment: function() {

        if (this.confidence == doc.reviewer.grade_3) this.confidence = doc.reviewer.grade_4;
        else if (this.confidence == doc.reviewer.grade_2) this.confidence = doc.reviewer.grade_3;
        else if (this.confidence == doc.reviewer.grade_1) this.confidence = doc.reviewer.grade_2;
    },

    decrement: function() {

        if (this.confidence == doc.reviewer.grade_4) this.confidence = doc.reviewer.grade_3;
        else if (this.confidence == doc.reviewer.grade_3) this.confidence = doc.reviewer.grade_2;
        else if (this.confidence == doc.reviewer.grade_2) this.confidence = doc.reviewer.grade_1;
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

    /* fire app:loaded */
    document.fire('app:loaded');
});