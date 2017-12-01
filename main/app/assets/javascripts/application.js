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

function getCookie(cname) {
  var name = cname + '=';
  var ca = document.cookie.split(';');
  for(var i = 0; i <ca.length; i++) {
      var c = ca[i];
      while (c.charAt(0)==' ') {
          c = c.substring(1);
      }
      if (c.indexOf(name) == 0) {
          return c.substring(name.length,c.length);
      }
  }
  return '';
}

// function removeCookie(cname) {
//     let value = '';
//     let days = -1;
//     let date, expires;
//     if (days) {
//         date = new Date();
//         date.setTime(date.getTime() + (days*24*60*60*1000));
//         expires = '; expires=' + date.toUTCString();
//     }
//     else {
//         expires = '';
//     }
//     document.cookie = cname + '=' + value + expires + '; path=/';
// }

function refreshToken(){
  var refresh_token = getCookie('refresh_token');
  if (refresh_token == '' || refresh_token == undefined){
    url_to('/users/logout')
  }else{
    data = {
      "grant_type" : "refresh_token",
      "refresh_token" : refresh_token
    }
    $.ajax({
        type:"POST",
        url:"/oauth/token",
        data: data,//{'node_uid':$nodeUid},//咱不做更改，只是用此参数
        // contentType: 'application/json; charset=utf-8',  
        // dataType: 'json',
        async:true,
        success:function(data){
          setCookie('access_token',data.access_token,1);
          setCookie('refresh_token',data.refresh_token,1);
        },
        error:function(data){
          url_to('/users/logout')
        }
      });
    }
}

function setCookie(name,value,days){ 
  // console.log(name);
  // console.log(value);
  // console.log(days);
  var date, expires;
  if (days) {
    date = new Date();
    date.setTime(date.getTime() + (days*24*60*60*1000));
    expires = '; expires=' + date.toUTCString();
  }
  else {
      expires = '';
  }
  document.cookie = name + '=' + value + expires + '; path=/';
  // document.cookie = "user_token=" + escape(data.access_token)
  // document.cookie = "refresh_token=" + escape(data.refresh_token)
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
