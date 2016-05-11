$(function () {
	$(function () {
		// 分析列表添加删除
		$('.add button').on("click",function(){
			var num = $('.analyserow').length;
			var numtext = $('.analyserow').find('.num');
			// 当多于一个的时候，第一个区块要加数字
			if(num == 1){
				numtext.html(num);
			}
			// clone 第一个区块			
			var $str = $(".analyselist").html();
			$(".add").before($str); 
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
	});

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
		$('#table_knowledge, #table_skill, #table_capacity').on("click",function(e){
			check_length($(this), $(e.target))
			// if($(e.target).is('input')){
			// 	var knowledge_length = $(this).find("input:checked").length
			// 	check_length($(e.target), knowledge_length);
			// }
			
 
 	// 		var chk_value_knowledge = [], $insert_html = $($("#hidden_analysis").prop("outerHTML"));
 			
 	// 		 $(this).find('input[type="checkbox"]:checked').each(function(i){

		// 		chk_value_knowledge.push($(this).parent().text());
		// 		if(this.value != ""){
		// 			$insert_html.find("input:first").val('knowledge');
		// 			$insert_html.find("input:eq(1)").val(this.value);
		// 			$insert_html.find("input:last").val($(this).parent().text());
		// 			$insert_html.attr('id', '');
		// 			$popFrom.append($insert_html.html());
		// 		}
			});
		// 	$popFrom.find('input[name="knowledge"]').val(chk_value_knowledge);			
	
		// });
		
		// $('#table_skill').on("click",function(){
		// 	var chk_value_skill =[]; 
		// 	 $(this).find('input[type="checkbox"]:checked').each(function(){      
		// 		chk_value_skill.push($(this).val());
		// 	});
		// 	$popFrom.find('input[name="skill"]').val(chk_value_skill);
		// });
		
		// $('#table_capacity').on("click",function(){
		// 	$(this).find('input[type="checkbox"]:checked')
		// 	var chk_value_capacity =[];	  
		// 	 $(this).find('input[type="checkbox"]:checked').each(function(){  
		// 		chk_value_capacity.push($(this).val());
		// 	});
		// 	$popFrom.find('input[name="capacity"]').val(chk_value_capacity);
		// });
	});
	
	//知识考察点添加到页面
	$("#button_analysis").on("click", function(){
		// 知识
		var chk_value_knowledge = [], $insert_html = $($("#hidden_analysis").prop("outerHTML"));
		var $modal = $("#myModal")
		$popFrom.find("input:hidden").remove();
		$modal.find('#table_knowledge input:checked').each(function(i){
			chk_value_knowledge.push($(this).parent().text());
			if(this.value != ""){				
				$insert_html.find("input:first").val('knowledge');
				$insert_html.find("input:eq(1)").val(this.value);
				$insert_html.find("input:last").val($(this).parent().text());
				
				$popFrom.append($insert_html.html());
			}
		});
		$popFrom.find('input[name="knowledge"]').val(chk_value_knowledge);	

			//技能
			var chk_value_skill =[];

			$modal.find('#table_skill input:checked').each(function(){      
				chk_value_skill.push($(this).parent().text());
				if(this.value != ""){				
					$insert_html.find("input:first").val('skill');
					$insert_html.find("input:eq(1)").val(this.value);
					$insert_html.find("input:last").val($(this).parent().text());

					$popFrom.append($insert_html.html());
				}
			});
			$popFrom.find('input[name="skill"]').val(chk_value_skill);

		//能力
		var chk_value_capacity =[];	  
		$modal.find('#table_capacity input:checked').each(function(){  
			chk_value_capacity.push($(this).parent().text());
			if(this.value != ""){				
				$insert_html.find("input:first").val('capacity');
				$insert_html.find("input:eq(1)").val(this.value);
				$insert_html.find("input:last").val($(this).parent().text());

				$popFrom.append($insert_html.html());
			}
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
	
	var check_length = function($element, $input_element){
		if($input_element.is('input')){
			var length = $element.find("input:checked").length
			if(length > 2){
				console.log($input_element);
				$input_element.attr('checked', false);
				alert('最多选择两个考察点');				
			}			
		}

	}

	// 初始化Modal
	$("#myModal").on("shown.bs.modal", function() {

		var selected_value = [];
		console.log($popFrom.html());
		var kv = $popFrom.find('input.dict_rid:hidden');
		$.each(kv, function(i, v){
			selected_value.push(v.value);			
		})

		// selected_value = $.merge(kv.split(','), sv.split(','), cv.split(','));

		// console.log(selected_value);

		// TODO: 选中
		$(this).find('input[type="checkbox"]').attr("checked",false);
		$(this).find('input[type="checkbox"]').val(selected_value);
		// 记录选中状态的值
//		$(function popFromValue(kv){
//			var knowledge1 =$("#knowledge1").val();
//			var arr = [];
//			var chk_value_knowledge = [];
//			chk_value_knowledge.push(kv);
//			
//			$('#table_knowledge').find('input[type="checkbox"]:checked').each(function(){      
//				
//			});
//			$popFrom.find('input[name="knowledge"]').val(chk_value_knowledge);
//		});
	
	});
	
	
	$("#myModal").on("hidden.bs.modal", function() {
//		$(this).removeData("bs.modal");
//		$(this).find('input[type="checkbox"]').attr("checked",false);
	});

	// 第一个块
	setInputsHandler($('.analyserow:first'));
});

// 分析列表添加删除
// $(function () {
// 	$('.add button').bind("click",function(){
// 		var num = $('.analyserow').length;
// 		num +=1;
		
// 		var $str = $($("#analysis ul:first").prop("outerHTML"));
// 		$str.find('li:first p:first label').html("得分点<span class='num'>" + num + "</span>");
// 		$str.find('li:first').before('<li class="del"><a href="javascript:void(0);">&times;</a></li>');
		
// 		$(".add").before($str.prop("outerHTML"));
		
// 		$(".del").on("click",function(){
// 			$(this).parent().remove();
// 			for(i=$(this).parent().index();i<num;i++){
// 				newnum = i+2;
// 				$('.analyserow .num').eq(i).html(newnum).attr('id', 'analyser' + newnum); 
// 			}
// 		});

// 	});	


// 	$(document).on("click", '.analyserow', function(e){
// 		analyser_id = $(this).attr('id');

// 		var $all_input = $("#" + analyser_id + " li:last input");

// 		var selected_value = "";

// 		$all_input.each(function(){ 
// 			if(this.value != "")
// 				selected_value += this.value;
// 		});

// 		if(selected_value == ""){
// 					$(".modal input").each(function(){ this.checked = false });//attr('checked', false);
// 				}else{
// 					alert(selected_value);
// 				}
				
// 			});
	
// 	$("#table_knowledge input").on("click", function(){
// 		var checked_size = $("#table_knowledge input:checked").size();
// 		if( checked_size > 2){
// 			alert('最多选择两个考察点');
// 			this.checked = false;
// 		}
// 		else{
// 			$knowledge = $("#knowledge");
// 			$knowledge.val(checked_size == 2 ? $knowledge.val() + ',' + this.value : this.value);
// 		}
// 	});



// });


