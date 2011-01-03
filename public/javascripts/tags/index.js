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

        /* organize and set json member */
        this.tags = new Hash;
        $('tags_json').innerHTML.evalJSON().collect(function(tag) {
            this.tags.set(tag['tag']['id'], tag['tag']);
        }.bind(this));

        /* build directory view */
        this.directoryView = new cDirectoryView(this.tags);

        /* reset documentsViews */
        this.documentsViews = new Hash;

        /* listen for hash change */
        //@todo find cross-browser solution
        window.onhashchange = this.onChange.bind(this);
    },

    onChange: function() {

            /* rerender? browser navigation used? */
            var hashValue = self.document.location.hash.substring(1)
            var rerender = hashValue != this.currentView;

            /* rerender */
            if (rerender) {
                if (hashValue == '') this.directoryView.render();
                else this.directoryView.openDirectory(hashValue);
            }
        }
});

var cDirectoryView = Class.create({
    
    html: null,

    initialize: function(tags) {

        /* build html string */
        
        //new file
        this.html = '<div class="icon_container rounded_border new_directory_container">\
          <div class="title new_directory">&nbsp;</div>\
          <div class="folder ">\
            <img class="new_directory" alt="" src="/images/organizer/folder-add-icon.png" />\
          </div>\
        </div>';

        //tags
        var tag;
        tags.each(function(tagArray) {

          tag = tagArray[1]
          this.html += '<div tag_id="'+tag['id']+'" class="icon_container rounded_border">\
              <div tag_id="'+tag['id']+'" class="title">'+tag['name']+'</div>\
              <div class="folder">\
                <img tag_id="'+tag['id']+'" class="folder" alt="" src="/images/organizer/folder-full-icon.png" />\
              </div>\
              <div class="folder_options">\
                <img class="rounded_border new_document" alt="" src="/images/organizer/add-icon.png" />\
                <img class="rounded_border" alt="" src="/images/organizer/play-icon.png" />\
                <img class="rounded_border destroy_directory" alt="" src="/images/organizer/remove-icon.png" />\
              </div>\
            </div>';
        }.bind(this));
    },

    render: function() {

        /* insert */
        $('icons').update(this.html)

        /* add listeners */

        //open directory
        $$('img.folder, .icon_container .title').each(function(element) {
            element.observe('click', function(event) {
                var tagId = event.target.getAttribute('tag_id');
                this.openDirectory(tagId);
            }.bind(this));
        }.bind(this));

        //new document
        $$('.new_document').each(function(element) {
            element.observe('click', this.createDocument.bind(this));
        }.bind(this));

        //new directory
        $$('.new_directory').each(function(element) {
            element.observe('click', this.createDirectory.bind(this));
        }.bind(this));

        //delete directory
        $$('.destroy_directory').each(function(element) {
            element.observe('click', this.destroyDirectory.bind(this));
        }.bind(this));

        /* set location hash */
        if (window.doc) doc.currentView = '';
        self.document.location.hash = '';
    },

    openDirectory: function(tagId) {

        /* get or create documentsView */
        var documentsView = doc.documentsViews.get(tagId);
        if (!documentsView) {
            documentsView = new cDocumentsView(doc.tags.get(tagId));
            doc.documentsViews.set(tagId, documentsView);
        }

        /* render documentsView */
        documentsView.render();
    },

    createDirectory: function(event) {

        /* request params */
        var tagName = prompt('What would you like to name the new directory?');

        /* request */
        new Ajax.Request('/tags/create', {
            method: 'post',
            parameters: {'name': tagName},
            onSuccess: function(transport) {

                /* inject json and rerender document */
                $('tags_json').update(Object.toJSON(transport.responseJSON));
                doc = new cDoc;
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
        new Ajax.Request('/tags/destroy', {
            method: 'post',
            parameters: {'id': tagId},
            onSuccess: function(transport) {

                /* inject json and rerender document */
                $('tags_json').update(Object.toJSON(transport.responseJSON));
                doc = new cDoc;
            },
            onFailure: function(transport) {
                alert('There was an error removing the directory.');
            }
        });
    },

    createDocument: function(event) {

        /* request params */
        var tagId = event.target.up('.icon_container').getAttribute('tag_id');

        /* post tag_id to documents/create action */
        $('tag_id').value = tagId;
        $('create_document').submit();
    }
});

var cDocumentsView = Class.create({

    html: null,
    tag : null,

    initialize: function(tag) {

        this.tag = tag

        /* build view html string */

        //return to root
        this.html = '<div class="icon_container rounded_border to_root_container">\
          <div class="title to_root">&nbsp;</div>\
          <div class="folder to_root">\
            <img class="to_root" alt="" src="/images/organizer/folder-up-icon.png" />\
          </div>\
        </div>';

        //new document
        this.html += '<div tag_id="'+tag['id']+'" class="icon_container rounded_border new_document_container">\
          <div class="title new_document">&nbsp;</div>\
          <div class="folder new_document">\
            <img class="new_document" alt="" src="/images/organizer/doc-new-icon.png" />\
          </div>\
        </div>';

        //document links
        this.tag.documents.each(function(document) {
          this.html += '<div document_id="'+document['id']+'" class="icon_container rounded_border">\
              <a href="/editor/'+document['id']+'">\
                <div class="title">'+document['name']+'</div>\
                <div class="folder">\
                  <img class="folder" alt="" src="/images/organizer/doc-icon.png" />\
                </div>\
              </a>\
              <div class="folder_options">\
                <a href="/editor/'+document['id']+'"><img class="rounded_border" alt="" src="/images/organizer/edit-icon.png" /></a>\
                <a href="/review/'+document['id']+'"><img class="rounded_border" alt="" src="/images/organizer/play-icon.png" /></a>\
                <img class="rounded_border remove_document" alt="" src="/images/organizer/remove-icon.png" />\
              </div>\
            </div>';
        }.bind(this));
    },

    render: function() {
        
        /* render doc title */
        $('directory_name').update('home/' + this.tag.name + '/');
        
        /* render view */
        $('icons').update(this.html);

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

        /* set location hash */
        doc.currentView = this.tag.id;
        self.document.location.hash = this.tag.id;
    },

    destroyDocument: function() {

        /* confirm */
        if (!confirm('Are you sure you want to delete this document? This cannot be undone.')) return;

        /* request params */
        var documentId = event.target.up('.icon_container').getAttribute('document_id');

        /* request */
        new Ajax.Request('/documents/destroy', {
            method: 'post',
            parameters: {'id': documentId},
            onSuccess: function(transport) {

                /* inject json and rerender document */
                $('tags_json').update(Object.toJSON(transport.responseJSON));
                doc = new cDoc;

                /* open appropriate directory */
                doc.directoryView.openDirectory(this.tag.id);
            }.bind(this),
            onFailure: function(transport) {
                alert('There was an error removing the directory.');
            }
        });
    }
});

/* global objects */
document.observe('dom:loaded', function() {
    doc = new cDoc;
    doc.onChange();
});