$(function () {
	// $(function () {
		// 分析列表添加删除
		var first_analyserow = $(".analyselist").html();
		$('.add button').on("click",function(){
			var num = $('.analyserow').length;
			var numtext = $('.analyserow').find('.num');
			// 当多于一个的时候，第一个区块要加数字
			if(num == 1){
				numtext.html(num);
			}
			// clone 第一个区块			
			// var $str = $(".analyselist");
			// $str.find("input:hidden").remove();
			$(".add").before(first_analyserow); 
			var $cloned = $(".add").prev();
			$cloned.find(".del").show();
			$cloned.find('.num').html(++num);
	 
			
			// 每个区块设置不同的ID
			var rowid = 'row'+ num;
			$cloned.attr("id", rowid);

			setInputsHandler($cloned);

			// 重新排序
			$cloned.find(".del").on("click",function(){
				$(this).parent().remove();
				var rows = $('.analyserow'), l = rows.length;
				for(var i=0; i<l; i++){
					var row = rows.eq(i);
					row.find('.num').html(i+1); 
				}
			});
		});
	// });

	$(function () {
		// 弹出层树状结构
		$('.tree li:has(ul)').addClass('parent_li').find(' > span').attr('title', 'Collapse this branch');
		$('.tree li.parent_li > span').on('click', function (e) {
			var children = $(this).parent('li.parent_li').find(' > ul > li');
			if (children.is(":visible")) {
				children.hide('fast');
				$(this).attr('title', 'Expand this branch').find(' > i').addClass('icon-plus-sign').removeClass('icon-minus-sign');
			} else {
				children.show('fast');
				$(this).attr('title', 'Collapse this branch').find(' > i').addClass('icon-minus-sign').removeClass('icon-plus-sign');
			}
			e.stopPropagation();
		});
	});
		

	// 知识点考察选择
	$(function checkbox(){
		$(document).on("click", '#table_knowledge, #table_skill, #table_capacity', function(e){
 			if($(e.target).is('input')){
				var length = $(this).find("input:checked").length
				if(length > 2){
					$(e.target).attr('checked', false);
					alert('最多选择两个考察点');				
				}			
			}
		});
	});
	
	//知识考察点添加到页面
	$(document).on("click", "#button_analysis", function(){
		// 知识
		var chk_value_knowledge = [], $insert_html = $($("#hidden_analysis").prop("outerHTML"));
		var $modal = $("#myModal")
		$popFrom.find("input:hidden").remove();
		$modal.find('#table_knowledge input:checked').each(function(i){
			chk_value_knowledge.push($(this).parent().text());
			add_hidden_input($insert_html, $popFrom, 'knowledge', this.value, $(this).attr('uid'), $(this).parent().text());
			 
		});
		$popFrom.find('input[name="knowledge"]').val(chk_value_knowledge);	

			//技能
			var chk_value_skill =[];

			$modal.find('#table_skill input:checked').each(function(){      
				chk_value_skill.push($(this).parent().text());
				add_hidden_input($insert_html, $popFrom, 'skill', this.value, $(this).attr('uid'), $(this).parent().text());
				
			});
			$popFrom.find('input[name="skill"]').val(chk_value_skill);

		//能力
		var chk_value_capacity =[];	  
		$modal.find('#table_capacity input:checked').each(function(){  
			chk_value_capacity.push($(this).parent().text());
			add_hidden_input($insert_html, $popFrom, 'capacity', this.value, $(this).attr('uid'), $(this).parent().text());
		});
		$popFrom.find('input[name="capacity"]').val(chk_value_capacity);

	})

	// 手工弹出Modal
	var $popFrom;
	var setInputsHandler = function($parent){
		$parent.find('.last input').click(function(){
			$popFrom = $(this).parent().parent();
			// $('#myModal').modal('show');
			// e.stopPropagation();
		});
	};

	// 初始化Modal
	$("#myModal").on("show.bs.modal", function() {

		var selected_value = [];
		var kv = $popFrom.find('input.dict_rid:hidden');
		$.each(kv, function(i, v){
			selected_value.push(v.value);			
		})

		// TODO: 选中
		$(this).find('input[type="checkbox"]').attr("checked",false).val(selected_value);		
	
	});

	var prev_version = '';
	$("#version").on("change", function(){
		if(this.value == "") return false;
		var is_data = $('.analyserow:first li.last p input').val();
		if((is_data != "" && confirm("更换教材版本会清空试题分析，确定更换吗？")) || is_data == ""){
			$.post('/checkpoints/get_nodes', "uid=" + $(this).find(':selected').attr('uid'), function(data){
				$("#myModal").html(data);
		  });
			prev_version = this.value;
 			$('ul.analyserow').remove();
			$(".analyselist").html(first_analyserow);
			setInputsHandler($('.analyserow:first'));
			
    }
    else{
    	this.value = prev_version;
    }
    });

	// 第一个块
	setInputsHandler($('.analyserow:first'));

	$(".anser_and_analyze").on("click", function(){
		$.get('/quizs/quiz_get', 'str_uid=' + $(this).attr('str_uid'), function(data){
			var data_json = jQuery.parseJSON(data);
			
			$("#answer").html("答案：" + data_json.data.obj_quizprop.answer);
			$("#answer_desc").html(data_json.data.obj_quizprop.desc);
			$("#answerModal").modal('show');
		})
	});
});

function add_hidden_input($insert_html, $popFrom, name, rid, uid, label){
	if(rid != ""){				
		$insert_html.find("input:first").val(name);
		$insert_html.find("input:eq(1)").val(rid);
		$insert_html.find("input:eq(2)").val(uid);
		$insert_html.find("input:last").val(label);

		$popFrom.append($insert_html.html());
	}
}

