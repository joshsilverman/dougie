/* class declarations */

var cDoc = Class.create({

    tags: null,

    directoryView: null,
    documentsViews: new Hash,

    initialize: function() {

        /* organize and set json member */
        this.tags = new Hash;
        $('tags_json').innerHTML.evalJSON().collect(function(tag) {
            this.tags.set(tag['tag']['id'], tag['tag']);
        }.bind(this));

        /* build and load directory view */
        this.directoryView = new cDirectoryView(this.tags);
        this.directoryView.render();
    }
});

var cDirectoryView = Class.create({
    
    html: '',

    initialize: function(tags) {

        /* build html string */
        
        //new file
        this.html += '<div class="icon_container rounded_border misc">\
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
            element.observe('click', this.openDirectory.bind(this));
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
    },

    openDirectory: function(event) {

        /* identify tag */
        var tagId = event.target.getAttribute('tag_id');

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

    html: '',
    tag : null,

    initialize: function(tag) {

        this.tag = tag

        /* build view html string */
        this.tag.documents.each(function(document) {
          this.html += '<div class="icon_container rounded_border">\
              <a href="/editor/'+document['id']+'">\
                <div class="title">'+document['name']+'</div>\
                <div class="folder">\
                  <img class="folder" alt="" src="/images/organizer/doc-icon.png" />\
                </div>\
              <\a>\
              <div class="folder_options">\
                <img class="rounded_border" alt="" src="/images/organizer/add-icon.png" />\
                <img class="rounded_border" alt="" src="/images/organizer/play-icon.png" />\
                <img class="rounded_border" alt="" src="/images/organizer/remove-icon.png" />\
              </div>\
            </div>';
        }.bind(this));
    },

    render: function() {
        
        /* render doc title */
        $('directory_name').update(this.tag.name + '/');
        Effect.BlindDown('directory_name');
        
        /* render view */
        $('icons').update(this.html);
    }
});

/* global objects */
document.observe('dom:loaded', function() {
    doc = new cDoc;
});