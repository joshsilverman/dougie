/*
Copyright (c) 2003-2010, CKSource - Frederico Knabben. All rights reserved.
For licensing, see LICENSE.html or http://ckeditor.com/license
*/

CKEDITOR.editorConfig = function( config ) {
    // Define changes to default configuration here. For example:
    // config.language = 'fr';
    // config.uiColor = '#AADC6E';

    config.contentsCss = '/stylesheets/documents/edit_contents.css';
    config.removePlugins = 'elementspath';
    config.resize_enabled = false;
    config.startupFocus = true;

    config.toolbar =  [
        
        ['BulletedList','-','Outdent','Indent'],
        ['Bold','Italic','Underline'],//,'Strike'],
        ['JustifyLeft','JustifyCenter','JustifyRight']//,'JustifyBlock'],
        //['Undo','Redo'],
        //['Cut','Copy','Paste','-','Print', 'SpellChecker'],
        //['Link','Unlink'],
        //['SpecialChar']
    ];
};
