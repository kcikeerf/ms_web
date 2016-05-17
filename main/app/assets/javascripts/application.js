// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require editor/ckeditor/ckeditor
//= require jquery
//= require jquery_ujs
//= require editor/js/main
//= require_tree .
//= require_self
//= require turbolinks


function url_to(url){
  window.location=url;
}

function url_to_blank(url){
  window.open(url);
}

function go_back(){
  window.history.go(-1)
}

function error_show(message){
	var html = '<div id="custom_error" class="modal fade" role="dialog" aria-labelledby="ModalLabel1"><div class="modal-dialog" role="document"><div class="modal-content"><div class="modal-header"><button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button><h4 class="modal-title" id="ModalLabel1">错误</h4></div><div class="modal-body"><div class="container-fluid"><dl class="clearfix"><dt><img src="/images/error.png" /></dt><dd><p>' + message + '</p></dd></dl></div></div><div class="modal-footer"><button type="button" class="btn btn-primary" data-dismiss="modal">确定</button></div></div></div></div>'
	$(html).modal();
}

$(document).on('ready page:load', function() {
  $.rails.allowAction = function(link) {
    if (!link.attr('data-confirm')) {
      return true;
    }
    $.rails.showConfirmDialog(link);
    return false;
  };
  $.rails.confirmed = function(link) {
    link.removeAttr('data-confirm');
    return link.trigger('click.rails');
  };
  return $.rails.showConfirmDialog = function(link) {
    var html, message;
    message = link.attr('data-confirm');

    html='<div class="modal fade" id="confirmationDialog" role="dialog" aria-labelledby="ModalLabel1""><div class="modal-dialog"><div class="modal-content"><div class="modal-header"><button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button><h4 class="modal-title" id="ModalLabel1">' + (link.data('name')) + '</h4></div><div class="modal-body"><div class="container-fluid"><dl class="clearfix"><dt><img src="/images/warning.png" /></dt><dd><p>' + message + '</p></dd></dl></div></div><div class="modal-footer"><a data-dismiss="modal" class="btn">' + (link.data('cancel')) + '</a><a data-dismiss="modal" class="btn btn-primary confirm">' + (link.data('ok'))+ '</a></div></div></div></div>';
    $(html).modal();
    return $(document).on('click', '#confirmationDialog .confirm', function() {
 	    return $.rails.confirmed(link);
    });
  };

});