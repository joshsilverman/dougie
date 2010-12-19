/*
Copyright (c) 2003-2010, CKSource - Frederico Knabben. All rights reserved.
For licensing, see LICENSE.html or http://ckeditor.com/license
*/

CKEDITOR.editorConfig = function( config ) {
    // Define changes to default configuration here. For example:
    // config.language = 'fr';
    // config.uiColor = '#AADC6E';

    config.removePlugins = 'elementspath';
    config.resize_enabled = false;

    config.toolbar =  [
        
        ['Save','Preview'],
        ['Cut','Copy','Paste','-','Print', 'SpellChecker'],
        ['Undo','Redo','-','Find','Replace','-','SelectAll','RemoveFormat'],
        '/',
        ['NumberedList','BulletedList','-','Outdent','Indent'],
        ['Bold','Italic','Underline','Strike','-','Subscript','Superscript'],
        ['JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock'],
        ['Link','Unlink'],
        ['SpecialChar'],
        ['Maximize']
    ];
};
