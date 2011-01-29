
/* dummy console log - ie, firebug disabled, ie, etc... */
if (!window.console) console = {log: function() {/* burppp */}};

/* class declaration */

//general utilities
var cAppUtilities = Class.create({

    Cookies: null,

    initialize: function() {
        
        this.Cookies = new this.cCookies;
        this.logXHR();
    },

    resizeContents: function() {

        /* calculations */
        var footer = $$('.footer')[0];
        var footerY = footer.getHeight();
        var viewportY = document.viewport.getHeight();
        var footerOffsetY = footer.cumulativeOffset()[1];

        var contents = $$('.contents')[0];
        var contentsY = contents.getHeight();

        var difference = viewportY - footerOffsetY - footerY;

        var newContentsY = contentsY + difference;

        /* set min height */
        contents.setStyle({'minHeight': newContentsY + 'px'});
    },

    requestCount: 0,
    logXHR: function() {

        /* monkey patch responders with wrappers */
        Ajax.Responders.dispatch = 
            Ajax.Responders.dispatch.wrap(function(dispatch, callback, request, transport, json) {
                
                if (callback == 'onComplete') console.log(transport);

                /* inject request */
                if (callback == 'onCreate') {
                    var params = request['parameters'];
                    delete params['_method'];
                    params = Object.toJSON(params).escapeHTML();
                    params = params.gsub('","', '",<br />"') + "<br /><br />"
                    params = "<div style='background-color:lightgrey'>{"+(AppUtilities.requestCount++)+" => {:request => </div>" + params + ','

                    $$('body')[0].insert({'bottom': params});
                }

                /* inject results */
                if (callback == 'onComplete') {
                    var response = transport['responseText'];
                    response = "<div style='background-color:lightgrey'>:request => </div>" + response + ","

                    $$('body')[0].insert({'bottom': response});
                }

                /* invoke original dispatch */
                return dispatch(callback, request, transport, json);
            });
    },

    /* utility classes */

    cCookies: Class.create({

        create: function(name,value,days) {
                if (days) {
                        var date = new Date();
                        date.setTime(date.getTime()+(days*24*60*60*1000));
                        var expires = "; expires="+date.toGMTString();
                }
                else var expires = "";
                document.cookie = name+"="+value+expires+"; path=/";
        },

        read: function (name) {
                var nameEQ = name + "=";
                var ca = document.cookie.split(';');
                for(var i=0;i < ca.length;i++) {
                        var c = ca[i];
                        while (c.charAt(0)==' ') c = c.substring(1,c.length);
                        if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
                }
                return null;
        },

        erase: function (name) {
                this.create(name,"",-1);
        }
    })
});

/* global vars */
var AppUtilities = new cAppUtilities;