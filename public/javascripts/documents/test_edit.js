var cTest = Class.create({

    users: [],

    initialize: function() {

        /* listeners */

        //start
        $('start_button').observe('click', function() {
            $R(1, parseInt($('user_count').value)).each(function(i) {
                this.users.push(new cUser(i));
            }.bind(this));
        }.bind(this));

        //stop
        $('stop_button').observe('click', this.stop.bind(this));

        //restart
        $('restart_button').observe('click', this.restart.bind(this));
    },

    stop: function() {
        this.users.each(function(user) {user.stop()});
    },

    restart: function() {

        /* make sure stopped */
        this.stop();

        /* restart */
        this.users.each(function(user) {user.restart()});
    }
});

var cUser = Class.create({

    updateTimerId: null,

    documentId: null,
    documentName: null,

    html: '',
    nodeCount:2,

    saveTimerId: null,

    beginUpdateRequest: null,

    stopped: false,

    initialize: function(i) {

        /* members from doc */
        this.documentName = i;

        /* if first user, check for id, html form elements */
        if (i == 1 && $('html') && $('id')) {

            /* set members */
            this.documentId = $('id').value;
            this.html = $('html').value;

            /* freeze users at 1 */


            /* call update */
            this.update.bind(this).delay(Math.random() * parseInt($('save_interval').value));
        }


        /* else, create new document */
        else this.create.bind(this).delay(Math.random() * 10);;
    },

    create: function() {
        
        new Ajax.Request('/documents/test_create', {
            onSuccess: function(transport) {

                /* update document id */
                this.documentId = transport.responseText;

                /* trigger first update */
                this.saveTimerId = this.update.bind(this).delay(Math.random() * parseInt($('save_interval').value));
            }.bind(this)
        });
    },

    update: function() {

        /* check if stop set */
        if (this.stopped) return;

        $R(1, parseInt($('new_node_count').value)).each(function() {
            this.html += '<p id="node_'+(this.nodeCount)+'" line_id="" changed="'+new Date().getTime()+'" class="outline_node" parent="node_0">'+(this.nodeCount++)+'Add some average weight to this line. Maybe just a few more words. And we stop</p>'
        }.bind(this));

        new Ajax.Request('/documents/test_update', {
            method: 'post',
            parameters: {id: this.documentId,
                         name: this.documentName,
                         html: this.html},
                     
            onCreate: function() {
                this.beginUpdateRequest = new Date().getTime();
            }.bind(this),

            onSuccess: function(transport) {
                this.html = transport.responseText;

                /* update average time */
                var updateCount = $('update_count');
                var averageUpdate = $('average_update');
                var requestTime = new Date().getTime() - this.beginUpdateRequest;
                averageUpdate.value = ((  (parseInt(averageUpdate.value) * parseInt(updateCount.value))
                                      + requestTime))
                                     / (parseInt(updateCount.value) + 1);

                /* update average_update */
                updateCount.value = parseInt(updateCount.value) + 1;

                /* last update */
                $('last_update').value = requestTime;

                /* initiate next update */
                this.saveTimerId = this.update.bind(this).delay(Math.random() * parseInt($('save_interval').value));
            }.bind(this)
        });
    },

    stop: function() {
        this.stopped = true;
        window.clearTimeout(this.saveTimerId);
    },

    restart: function() {
        this.stopped = false;
        this.saveTimerId = this.update.bind(this).delay(Math.random() * parseInt($('save_interval').value));
    }
});

document.observe('dom:loaded', function() {
    test = new cTest;
})
