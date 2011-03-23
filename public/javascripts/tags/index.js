/* class declarations */

var cDoc = Class.create({

    /* parsed tag info */
    tags: null,

    /* views */
    directoryView: null,
    documentsViews: null,

    /* holds tagId of current documentsView or and empty string */
    currentView: null,

    initialize: function() {

        /* check for reload cookie */
        var reload = AppUtilities.Cookies.read('reloadOrganizer') == 'true';
//        AppUtilities.Cookies.erase('reloadOrganizer')
        if (reload) {
            //self.document.location.reload(true);
            new Ajax.Request('/tags/json', {
                asynchronous: false,
                onSuccess: function(transport) {$('tags_json').innerHTML = transport.responseText;}});
        }

        /* organize and set json member */
        this.tags = [];
        $('tags_json').innerHTML.evalJSON().collect(function(tag) {
            this.tags.push([tag['tag']['id'], tag['tag']]);
        }.bind(this));

        /* build directory view */
        this.directoryView = new cDirectoryView(this.tags);

        /* build quick study */
        this.quickStudyParser();

        /* reset documentsViews */
        this.documentsViews = new Hash;

        /* listen for hash change */
        //@todo find cross-browser solution
        window.onhashchange = this.onChange.bind(this);

        /* resize listener */
        window.onresize = AppUtilities.resizeContents;
    },

    onChange: function() {

        /* rerender? browser navigation used? */
        var hashValue = self.document.location.hash.substring(1);
        var rerender = hashValue != this.currentView;
        
        /* rerender */
        if (rerender) {
            if (hashValue == '') this.directoryView.render();
            else this.directoryView.openDirectory(hashValue);
        }
        /* fire resize */
        AppUtilities.resizeContents();
        AppUtilities.resizeContents.delay(.01);
    },

    quickStudyParser: function(){
        var card = $('qstudy_json').innerHTML;
        var front;
        var back;
        var defParts = card.split(' - ');

        if (defParts.length > 1) {
            front = defParts[0];
            back = defParts[1];
        }
        $('card_front').innerHTML = front;
        $('card_back').innerHTML = back;
    }
});

var cDirectoryView = Class.create({

    tags: null,
    html: null,

    sortBy: 'updated_at',
    reverse: false,

    initialize: function(tags) {
        /* set tags */
        this.tags = tags;

        /* sort (builds html) and render */

        //if rebuilding view, reset active
        var updatedAt = $('sort_by_updated_at');
        if (updatedAt) updatedAt.removeClassName('active');

        //sort
        this.sort('updated_at');
    },

    _buildHtml: function() {

        /* new file */
        this.html = '<div class="icon_container rounded_border new_directory_container">\
          <div class="title new_directory">&nbsp;</div>\
          <div class="folder ">\
            <img class="new_directory" alt="" src="/images/organizer/folder-add-icon.png" />\
          </div>\
        </div>';

        /* tags */
        var tag;
        this.tags.each(function(tagArray) {

          tag = tagArray[1]
          this.html += '<div tag_id="'+tag['id']+'" class="icon_container rounded_border">\
              <div tag_id="'+tag['id']+'" class="title">'+tag['name']+'</div>\
              <div class="folder" tag_id="'+tag['id']+'" >\
                <img tag_id="'+tag['id']+'" class="folder" alt="" src="/images/organizer/folder-full-icon.png" />\
              </div>\
              <div class="folder_options">\
                <img class="rounded_border new_document" alt="" src="/images/organizer/add-icon.png" />\
                <a href="/review/dir/'+tag['id']+'"><img class="rounded_border" alt="" src="/images/organizer/play-icon.png" /></a>\
                <img class="rounded_border destroy_directory" alt="" src="/images/organizer/remove-icon.png" />\
              </div>\
            </div>';
        }.bind(this));
    },

    render: function() {
        /* render icons and title */
        $('directory_name').update('/');
        $('icons').update(this.html)

        /* remove old sort listeners/classes; add new classes */
        $('sort_options').childElements().each(function(element) {
            element.stopObserving();
            element.removeClassName('reverse');
            element.removeClassName('active');
        });
        $('sort_by_' + this.sortBy).addClassName('active');
        if (this.reverse) $('sort_by_' + this.sortBy).addClassName('reverse');

        /* add listeners */

        //open directory
        $$('div.folder, img.folder, .icon_container .title').each(function(element) {
            element.observe('click', function(event) {
                var tagId = event.target.getAttribute('tag_id');
                this.openDirectory(tagId);
                event.stop();
            }.bind(this));
        }.bind(this));

        //new directory
        $$('.new_directory, div.new_directory, .new_directory_container .folder').each(function(element) {
            element.observe('click', this.createDirectory.bind(this));
        }.bind(this));

        //new document
        //@todo new_document and delete_directory could be combined for a modest
        //      performance gain
        $$('.new_document').each(function(element) {
            element.observe('click', this.createDocument.bind(this));
        }.bind(this));


        //delete directory
        $$('.destroy_directory').each(function(element) {
            element.observe('click', this.destroyDirectory.bind(this));
        }.bind(this));

        //sort
        $('sort_by_updated_at').observe('click', function() {
            this.sort('updated_at');
            this.render();
        }.bind(this));
        $('sort_by_name').observe('click', function() {
            this.sort('name');
            this.render();
        }.bind(this));
        
        /* set location hash */
        if (window.doc) doc.currentView = "";
        self.document.location.hash = '#';
    },

    openDirectory: function(tagId) {

        /* get or create documentsView */
        var documentsView = doc.documentsViews.get(tagId);
        if (!documentsView) {
            var tag;
            doc.tags.each(function(t) {
               if (t[0] == tagId) {
                   tag = t[1];
                   throw $break;
               }
            });

            documentsView = new cDocumentsView(tag);
            doc.documentsViews.set(tagId, documentsView);
        }

        /* render documentsView */
        documentsView.render();
    },

    createDirectory: function(event) {

        /* stop bubble */
        event.stop();

        /* request params */
        var tagName = prompt('What would you like to name the new directory?');
        if (!tagName) return;

        /* request */
        new Ajax.Request('/tags', {
            method: 'post',
            parameters: {'name': tagName},
            onSuccess: function(transport) {

                /* inject json and rerender document */
                $('tags_json').update(Object.toJSON(transport.responseJSON));
                doc = new cDoc;
                doc.onChange();
            },
            onFailure: function(transport) {
                alert('There was an error saving the new directory.');
            }
        });
    },

    destroyDirectory: function(event) {

        /* confirm */
        if (!confirm('Are you sure you want to delete this directory and all of it\'s contents? This cannot be undone.')) return;

        /* request params */
        var tagId = event.target.up('.icon_container').getAttribute('tag_id');

        /* request */
        new Ajax.Request('/tags/' + tagId, {
            method: 'delete',
            onSuccess: function(transport) {

                /* inject json and rerender document */
                $('tags_json').update(Object.toJSON(transport.responseJSON));
                doc = new cDoc;
                doc.onChange();
            },
            onFailure: function(transport) {
                alert('There was an error removing the directory.');
            }
        });
    },

    createDocument: function(event) {

        /* stop bubble */
        event.stop();

        /* set reload cookie */
        AppUtilities.Cookies.create('reloadOrganizer', true, 1)

        /* request params */
        var tagId = event.target.up('.icon_container').getAttribute('tag_id');

        /* new document */
        self.document.location.href = '/documents/create/' + tagId
        
    },

    sort: function(attribute) {

        this.sortBy = attribute;

        /* sort */
        this.tags = this.tags.sortBy(function(tag) {return tag[1][attribute].toLowerCase();});

        /* reverse? dom attributes */
        var sortBy = $('sort_by_' + attribute);
        var activeCurrent = sortBy.hasClassName('active');
        if (!activeCurrent) sortBy.addClassName('active');
        var reverseCurrent = sortBy.hasClassName('reverse');
        this.reverse = (activeCurrent && !reverseCurrent);
        if (this.reverse) {
            sortBy.addClassName('reverse');
            this.tags = this.tags.reverse();
        }
        else $('sort_by_' + attribute).removeClassName('reverse');

        //special handling for updated_at - it's backwards
        if (attribute == 'updated_at') this.tags = this.tags.reverse();

        /* remove classnames from inactive */
        $('sort_options').childElements().each(function(sortBy) {
            if (sortBy.id != 'sort_by_' + attribute) {
                sortBy.removeClassName('reverse');
                sortBy.removeClassName('active');
            }
        });

        /* build html */
        this._buildHtml();
    }
});

var cDocumentsView = Class.create({

    html: null,
    tag : null,

    sortBy: 'updated_at',
    reverse: false,

    initialize: function(tag) {

        /* tag member */
        this.tag = tag;

        /* sort (builds html) */
        /* remove old sort listeners/classes; add new classes */
        $('sort_options').childElements().each(function(element) {
            element.stopObserving();
            element.removeClassName('reverse');
            element.removeClassName('active');
        });
        this.sort('updated_at');
    },

    _buildHtml: function() {
        
        /* build view html string */

        //return to root
        this.html = '<div class="icon_container rounded_border to_root_container">\
          <div class="title to_root">&nbsp;</div>\
          <div class="folder to_root">\
            <img class="to_root" alt="" src="/images/organizer/folder-up-icon.png" />\
          </div>\
        </div>';

        //new document
        this.html += '<div tag_id="'+this.tag['id']+'" class="icon_container rounded_border new_document_container">\
          <div class="title new_document">&nbsp;</div>\
          <div class="folder new_document">\
            <img class="new_document" alt="" src="/images/organizer/doc-new-icon.png" />\
          </div>\
        </div>';

        //document links
        this.tag.documents.each(function(document) {
          this.html += '<div document_id="'+document['id']+'" class="icon_container rounded_border">\
              <a href="/documents/'+document['id']+'/edit">\
                <div class="title">'+document['name']+'</div>\
                <div class="folder">\
                  <img class="folder" alt="" src="/images/organizer/doc-icon.png" />\
                </div>\
              </a>\
              <div class="folder_options">\
                <a href="/documents/'+document['id']+'/edit"><img class="rounded_border" alt="" src="/images/organizer/edit-icon.png" /></a>\
                <a href="/review/'+document['id']+'"><img class="rounded_border" alt="" src="/images/organizer/play-icon.png" /></a>\
                <img class="rounded_border remove_document" alt="" src="/images/organizer/remove-icon.png" />\
              </div>\
            </div>';
        }.bind(this));
    },

    render: function() {
        
        /* render view and title*/
        var dirName;
        if (this.tag.misc) dirName = this.tag.name
        else dirName = this.tag.name + " <span id='edit_directory_name'>[Edit Name]</span>"
        $('directory_name').update('/' + dirName + '/');
        $('icons').update(this.html);

        /* remove old sort listeners/classes; add new classes */
        $('sort_options').childElements().each(function(element) {
            element.stopObserving();
            element.removeClassName('reverse');
            element.removeClassName('active');
        });
        $('sort_by_' + this.sortBy).addClassName('active');
        if (this.reverse) $('sort_by_' + this.sortBy).addClassName('reverse');
        var edit_directory_name = $('edit_directory_name');
        if (edit_directory_name) edit_directory_name.stopObserving();

        /* listeners */

        //to root
        $$('.to_root').each(function(element) {
            element.observe('click', doc.directoryView.render.bind(doc.directoryView));
        });

        //new document
        $$('.new_document').each(function(element) {
            element.observe('click', doc.directoryView.createDocument);
        });

        //remove document
        $$('.remove_document').each(function(element) {
            element.observe('click', this.destroyDocument.bind(this));
        }.bind(this));

        //edit dir name listeners
        if (edit_directory_name) edit_directory_name.observe('click', this.editDirName.bind(this));

        /* sort listeners */
        $('sort_by_updated_at').observe('click', function() {
            this.sort('updated_at');
            this.render();
        }.bind(this));
        $('sort_by_name').observe('click', function() {
            this.sort('name');
            this.render();
        }.bind(this));

        /* set location hash */
        doc.currentView = this.tag.id;
        self.document.location.hash = this.tag.id;
    },

    destroyDocument: function(event) {

        /* confirm */
        if (!confirm('Are you sure you want to delete this document? This cannot be undone.')) return;

        /* request params */
        var documentId = event.target.up('.icon_container').getAttribute('document_id');

        /* request */
        new Ajax.Request('/documents/' + documentId, {
            method: 'delete',
            onSuccess: function(transport) {

                /* inject json and rerender document */
                $('tags_json').update(Object.toJSON(transport.responseJSON));
                doc = new cDoc;
                doc.onChange();

                /* open appropriate directory */
                doc.directoryView.openDirectory(this.tag.id);
            }.bind(this),
            onFailure: function(transport) {
                alert('There was an error removing the directory.');
            }
        });
    },

    editDirName: function() {

        /* request params */
        var tagName = prompt('What would you like to rename the directory?');
        if (!tagName) return;
        
        /* request */
        new Ajax.Request('/tags/' + doc.currentView, {
            method: 'put',
            parameters: {'name': tagName,
                         'id': doc.currentView},
            onSuccess: function(transport) {

                /* inject json and rerender document */
                // @todo clear area for optimization at if latency becomes a problem
                $('tags_json').update(Object.toJSON(transport.responseJSON));
                doc = new cDoc;
                doc.onChange();
            },
            onFailure: function(transport) {
                alert('There was an error updating the directory name.');
            }
        });
    },

    sort: function(attribute) {

        /* sortBy */
        this.sortBy = attribute;

        /* sort */
        this.tag.documents = this.tag.documents.sortBy(function(doc) {return doc[attribute].toLowerCase();});

        /* reverse? dom attributes */
        var activeCurrent = $('sort_by_' + attribute).hasClassName('active');
        if (!activeCurrent) $('sort_by_' + attribute).addClassName('active');
        var reverseCurrent = $('sort_by_' + attribute).hasClassName('reverse');
        this.reverse = (activeCurrent && !reverseCurrent)
        if (this.reverse) {
            $('sort_by_' + attribute).addClassName('reverse');
            this.tag.documents = this.tag.documents.reverse();
        }
        else $('sort_by_' + attribute).removeClassName('reverse');

        //special handling for updated_at - it's backwards
        if (attribute == 'updated_at') this.tag.documents = this.tag.documents.reverse();

        /* remove classnames from inactive */
        $('sort_options').childElements().each(function(sortBy) {
            if (sortBy.id != 'sort_by_' + attribute) {
                sortBy.removeClassName('reverse');
                sortBy.removeClassName('active');
            }
        });

        /* build html */
        this._buildHtml();
    }
});

/* global objects */
document.observe('dom:loaded', function() {
    doc = new cDoc;
    doc.onChange();

    /* fire app:loaded */
    document.fire('app:loaded');
});