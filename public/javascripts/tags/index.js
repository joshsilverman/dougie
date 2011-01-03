/* class declarations */

var cDoc = Class.create({

    tags: new Hash,

    directoryView: null,
    documentsViews: new Hash,

    initialize: function() {

        /* organize and set json member */
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
          <div class="title">New folder</div>\
          <div class="folder">\
            <img alt="" src="/images/organizer/folder-add-icon.png" />\
          </div>\
        </div>';

        //tags
        var tag;
        tags.each(function(tagArray) {

          tag = tagArray[1]
          this.html += '<div class="icon_container rounded_border">\
              <div tag_id="'+tag['id']+'" class="title">'+tag['name']+'</div>\
              <div class="folder">\
                <img tag_id="'+tag['id']+'" class="folder" alt="" src="/images/organizer/folder-full-icon.png" />\
              </div>\
              <div class="folder_options">\
                <img alt="" src="/images/organizer/add-icon.png" />\
                <img alt="" src="/images/organizer/play-icon.png" />\
                <img alt="" src="/images/organizer/process-icon.png" />\
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
    }
});

var cDocumentsView = Class.create({

    html: '',

    initialize: function(tag) {

        tag.documents.each(function(document) {

          this.html += '<div class="icon_container rounded_border">\
              <div tag_id="'+document['id']+'" class="title">'+document['name']+'</div>\
              <div class="folder">\
                <img tag_id="'+document['id']+'" class="folder" alt="" src="/images/organizer/doc-icon.png" />\
              </div>\
              <div class="folder_options">\
                <img alt="" src="/images/organizer/add-icon.png" />\
                <img alt="" src="/images/organizer/play-icon.png" />\
                <img alt="" src="/images/organizer/process-icon.png" />\
              </div>\
            </div>';
        }.bind(this));
    },

    render: function() {$('icons').update(this.html);}
});

/* global objects */
document.observe('dom:loaded', function() {
    doc = new cDoc;
});