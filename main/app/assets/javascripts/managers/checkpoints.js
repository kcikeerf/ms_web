//= require ztree/js/jquery.ztree.core
//= require ztree/js/jquery.ztree.excheck
//= require ztree/js/jquery.ztree.exedit
//= require_self

var setting = {
		view: {
			addHoverDom: addHoverDom,
			removeHoverDom: removeHoverDom,
			selectedMulti: false
		},
		check: {
			enable: true,
			chkStyle: 'checkbox',
			radioType: "level"
		},
		data: {
			simpleData: {
				enable: true,
				idKey: "rid",
				pIdKey: "pid", //pid父节点唯一标识符属性名称
				rootPId: null
			}
		},
		callback: {
			beforeRemove: zTreeBeforeRemove,
			beforeEditName: zTreeBeforeEditName,
			beforeDrag: zTreeBeforeDrag,
			beforeDrop: zTreeBeforeDrop
//			onDrop: zTreeOnDrop,
			
		},
		edit: {
			enable: true
		}
	};
	/*显示自定义控件和添加事件*/
	function addHoverDom(treeId, treeNode) {
		//tId是每个节点的唯一id字符，跟在什么层级没有关系;
		var sObj = $("#" + treeNode.tId + "_span");
		if (treeNode.editNameFlag || $("#addBtn_" + treeNode.tId).length > 0) return;
		var addStr = "<span class='button add' id='addBtn_" + treeNode.tId + "' title='add node' onfocus='this.blur();'></span>";
		sObj.after(addStr);
		var addBtn = $("#addBtn_" + treeNode.tId);
		var deleteBtn = $("#"+treeNode.tId+"_remove")
		//出现增加节点之后的绑定的事件;
		if (addBtn) {
			addBtn.unbind('click');
			addBtn.on("click", function(){
				$('.checkpoint').val('');
				$('.desc').val('');
				$('#advice').val('');
				$('#sort').val('');
				$('#select-box').val('');
			    $('#dlg').dialog('open');
			    $('.dimesion').val(treeNode.dimesion);
			    $('.str_pid').val(treeNode.rid);
			   	$("#save").on('click',function(){
			   		if($('#select-box').val() != ''){
			   			$.post('/managers/checkpoints', $("#fm").serialize(), function(data){
				   		 	if(data.status == 200){
				   		 		var tree = $.fn.zTree.getZTreeObj(treeNode.dimesion + "_tree");
				   		 		tree.addNodes(treeNode, data.data)
				   		 	}else{
				   		 		return;
				   		 	}
				   		});
			   		}else{
			   			alert('请选择教材目录');
			   		};
			   		$('.checkpoint').val('');
					$('.desc').val('');
					$('#select-box').val('');
					$('#save').off('click');
					$('#dlg').dialog('close');
			   	})
			    return false;
			});
		}
	};
	/*删除事件*/
	function zTreeBeforeRemove(treeId, treeNode) {
		
		var isOk;
		if(confirm("你确定要删除么？")){	
		
			$.ajax({
				async: false,
				type:"delete",
				url:"/managers/checkpoints/"+treeNode.uid,
				success:function(data){
					if(data.status == 200){
						isOk = true;
					}else{
						isOk = false;
					}
				},
				error:function(data){
					isOk = false;
				}
			})
			return isOk;
		}
		return false;		

	}
	/*隐藏自定义控件*/
	function removeHoverDom(treeId, treeNode) {
		$("#addBtn_" + treeNode.tId).unbind().remove();
	};
	/*编辑事件*/
	function zTreeBeforeEditName(treeId, treeNode){
		$('#dlg').dialog('open');
		$('.checkpoint').val(treeNode.checkpoint);
		treeNode.desc ? $('.desc').val(treeNode.desc) : $('.desc').val('');
		treeNode.advice ? $('#advice').val(treeNode.advice) : $('#advice').val('');
		treeNode.sort ? $('#sort').val(treeNode.sort) : $('#sort').val('');
                treeNode.uid ? $('.ckp_uid').val(treeNode.uid) : "";
	  	$.get("/managers/checkpoints/"+treeNode.uid+"/edit",{},function(data){
			var len = data.data.length;
			var arr=[];
			for(var i=0;i<len;i++){
				arr.push(data.data[i].cat_uid);
			}
			$('#select-box').val(arr);
		})
		$('#save').unbind('click');
		$('#save').on('click',function(){
			var nodeName = $('.checkpoint').val();
			var _this = $(this);
			$.ajax({
				type:"put",
				url:"/managers/checkpoints/"+treeNode.uid,
				data:$('#fm').serialize(),
				success:function(data){
					treeNode.checkpoint = nodeName;
					$("#"+treeNode.tId+"_span").text(nodeName);
					_this.off('click');
				},
				error:function(data){
					_this.off('click');
				}
			})
			$('#dlg').dialog('close');
		});
	  	return false;
	}
	var DragUid;
	var DragParentUid;
	/*拖拽之前的事件回调函数*/
	function zTreeBeforeDrag(treeId, treeNodes){
		DragUid = treeNodes[0].uid;
		return DragUid;
		
	}
	function zTreeBeforeDrop(treeId, treeNodes, targetNode, moveType){
		var isOk = false;
		DragParentUid = targetNode.uid;
		$.ajax({
			type:"POST",
			dataType:"JSON",
			async:false,
			data:{str_pid:DragParentUid},
			url:"/managers/checkpoints/"+DragUid+"/move_node",
			success:function(data){
				if(data.status == 200){
					alert('拖拽成功')
					isOk = true;
				}else{
					alert(data.data.message);
				}
			},
			error:function(){
				return;
			}
		});
		return isOk;
	}
	$(document).ready(function(){
		var node_uid;
		var $subject = $('#subject');
		var $grades = $('#grades');
		var $texType = $('#texType');
		var $texVolume = $('#texVolume');
		$('#subject').on('change',function(){
			if($(this).val() != ''){
				$.get('/node_structures/get_grades',{subject:$(this).val()},function(data){
					var len = data.length;
					var str = '';
					for(var i=0;i<len;i++){
						str += '<option value="'+data[i].name+'">'+data[i].label+'</option>';
					}
					$grades.append(str);
				})
			}else{
				$grades.find('option:gt(0)').remove();
				$texType.find('option:gt(0)').remove();
			}
		})
		/*年级改变*/
		$grades.on('change',function(){
			var $subjectVal = $subject.val();
			var $gradeVal = $(this).val();
			if($(this).val() != ''){
				$texType.find('option:gt(0)').remove();
				$.get('/node_structures/get_versions',{subject:$subjectVal,grade:$gradeVal},function(data){
					var len = data.length;
					var str = '';
					for(var i=0;i<len;i++){
						str += '<option value="'+data[i].name+'" data-uid="'+data[i].node_uid+'">'+data[i].label+'</option>';
					}
					$texType.append(str);
				});
			}else{
				$texType.find('option:gt(0)').remove();
				
			}
		})
		/*教材改变*/
		$texType.on('change',function(){
			var $subjectVal = $subject.val();
			var $gradeVal = $grades.val();
			var $texTypeVal =  $(this).val();
			if($(this).val() != ''){
				$texVolume.find('option:gt(0)').remove();
				$.get('/node_structures/get_units',{subject:$subjectVal,grade:$gradeVal,version:$texTypeVal},function(data){
					var len = data.length;
					var str = '';
					for(var i=0;i<len;i++){
						str += '<option value="'+data[i].name+'" data-uid="'+data[i].node_uid+'">'+data[i].label+'</option>';
					}
					$texVolume.append(str);
				})
			}else{
				$texVolume.find('option:gt(0)').remove();
			}
			
		});
		$texVolume.on('change',function(){
			var $uid = $(this).find('option:selected').attr('data-uid');
			if($(this).val() == ''){
				$.fn.zTree.init($("#skill_tree"), setting, null);
				$.fn.zTree.init($("#ability_tree"), setting, null);
				$.fn.zTree.init($("#knowledge_tree"), setting, null);
				$('#file_upload').hide();
			}else{
				$.get('/node_structures/get_catalogs_and_tree_data',{node_uid:$uid},function(data){
					var zNodes_knowledge = data.knowledge.nodes;
					var zNodes_skill = data.skill.nodes;
					var zNodes_ability = data.ability.nodes;
					$.fn.zTree.init($("#knowledge_tree"), setting, zNodes_knowledge);
					$.fn.zTree.init($("#skill_tree"), setting, zNodes_skill);
					$.fn.zTree.init($("#ability_tree"), setting, zNodes_ability);
					var len = data.catalogs.length;
					var str = '';
					for(var i=0;i<len;i++){
						str += '<option value="'+data.catalogs[i].uid+'">'+data.catalogs[i].node+'</option>'
					}
					$('#select-box').html(str);
					$('.node_uid').val($uid);
					$('#file_upload').show();
				})
			}
		})
	})
