//= require_self
//= require editor/ckeditor/ckeditor
//= require editor/ckeditor/config
//= require editor/js/main

(function() {
  if (typeof window['CKEDITOR_BASEPATH'] === "undefined" || window['CKEDITOR_BASEPATH'] === null) {
    window['CKEDITOR_BASEPATH'] = "/ckeditor/";
  }
}).call(this);
