//= require jquery-min
//= require jquery-ui.min
//= require jquery_ujs
//= require bootstrap.min
//= require_self
//= require jquery_lib/jquery.center
// require turbolinks

function centerModals(){
      $('.modal').each(function(i){
        var $clone = $(this).clone().css('display', 'block').appendTo('body');
        var top = Math.round(($clone.height() - $clone.find('.modal-content').height()) / 2);
        top = top > 0 ? top : 0;
        $clone.remove();
        $(this).find('.modal-content').css("margin-top", top);
      });
    }
$('.modal').on('show.bs.modal', centerModals);
$(window).on('resize', centerModals);

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
  
  $.rails.showConfirmDialog = function(link) {
    var html, message;
    message = link.attr('data-confirm');

    html='<div class="modal fade" id="confirmationDialog" role="dialog" aria-labelledby="ModalLabel1""><div class="modal-dialog"><div class="modal-content"><div class="modal-header"><button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button><h4 class="modal-title" id="ModalLabel1">' + (link.data('name')) + '</h4></div><div class="modal-body"><div class="container-fluid"><dl class="clearfix"><dt><img src="/images/warning.png" /></dt><dd><p>' + message + '</p></dd></dl></div></div><div class="modal-footer"><a data-dismiss="modal" class="btn">' + (link.data('cancel')) + '</a><a data-dismiss="modal" class="btn btn-primary confirm">' + (link.data('ok'))+ '</a></div></div></div></div>';
    $(html).modal();
    return $(document).on('click', '#confirmationDialog .confirm', function() {
 	    return $.rails.confirmed(link);
    });
  };

});
