//= require jquery-min
//= require bootstrap.min
//= require_self

$(function(){
	$('#report_menus .report_click_menu').on('click',function(){
        var target_url = $(this).attr('reporturl');
		$('#reportShowField').attr("src", target_url);
	});
}); 