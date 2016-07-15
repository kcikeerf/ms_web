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
				idKey: "id",
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
		if (addBtn) addBtn.on("click", function(){
			$('.checkpoint').val('');
			$('.desc').val('');
			// $('#select-box').val('');
		    $('#dlg').dialog('open');
		    $('.dimesion').val(treeNode.dimesion);
		    $('.str_pid').val(treeNode.rid);
		   	$("#save").on('click',function(){
		   		// console.log($('#select-box').val());
		   			$.post('/managers/subject_checkpoints', $("#fm").serialize(), function(data){
			   		 	if(data.status == 200){
			   		 		console.log(data.data);
			   		 		var tree = $.fn.zTree.getZTreeObj(treeNode.dimesion + "_tree");
			   		 		tree.addNodes(treeNode, data.data);
			   		 	}

			   		});
		   		
		   	$('.checkpoint').val('');
				$('.desc').val('');
				// $('#select-box').val('');
				$('#save').off('click');
				$('#dlg').dialog('close');
		   	})
		    return false;
		});
	};
	/*删除事件*/
	function zTreeBeforeRemove(treeId, treeNode) {
		
		var isOk;
		if(confirm("你确定要删除么？")){	
		
			$.ajax({
				async: false,
				type:"delete",
				url:"/managers/subject_checkpoints/"+treeNode.uid,
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
		treeNode.desc?$('.desc').val(treeNode.desc):$('.desc').val('');
		treeNode.advice ? $('#advice').val(treeNode.advice) : $('#advice').val('');
	  	$.get("/managers/subject_checkpoints/"+treeNode.uid+"/edit",{},function(data){
			var len = data.data.length;
			var arr=[];
			for(var i=0;i<len;i++){
				arr.push(data.data[i].cat_uid);
			}
			// $('#select-box').val(arr);
		})
		$('#save').on('click',function(){
			var nodeName = $('.checkpoint').val();
			var _this = $(this);
			$.ajax({
				type:"put",
				url:"/managers/subject_checkpoints/"+treeNode.uid,
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
			url:"/managers/subject_checkpoints/"+DragUid+"/move_node",
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

	//读取指标
  function get_tree_data(subject){
		if(subject == ''){
			init_tree(null, null, null);
		}else{
			$.get('/node_structures/get_tree_data_by_subject',{subject: subject},function(data){
				var zNodes_knowledge = data.knowledge.nodes;
				var zNodes_skill = data.skill.nodes;
				var zNodes_ability = data.ability.nodes;
				init_tree(zNodes_knowledge, zNodes_skill, zNodes_ability);

				$('.subject').val(subject);
			})
		}
	}

	//读取科目、教材指标
  function get_subject_volume_tree_data(subject, node_structure_uid){	
		$.get('/managers/subject_checkpoints/get_subject_volume_ckps',{node_structure_uid: node_structure_uid, subject: subject},function(data){
			var zNodes_knowledge = data.knowledge;
			var zNodes_skill = data.skill;
			var zNodes_ability = data.ability;
			init_tree(zNodes_knowledge, zNodes_skill, zNodes_ability);
		});
	}

	//读取教材、目录指标
  function get_volume_catalog_tree_data(node_structure_uid, node_catalog_uid){
		$.get('/managers/subject_checkpoints/get_volume_catalog_ckps',{node_structure_uid: node_structure_uid, node_catalog_uid: node_catalog_uid},function(data){
			var zNodes_knowledge = data.knowledge;
			var zNodes_skill = data.skill;
			var zNodes_ability = data.ability;
			init_tree(zNodes_knowledge, zNodes_skill, zNodes_ability);
		});
	}

	function init_tree(knowledge, skill, ability){
		$.fn.zTree.init($("#skill_tree"), setting, skill);
		$.fn.zTree.init($("#ability_tree"), setting, ability);
		$.fn.zTree.init($("#knowledge_tree"), setting, knowledge);
	}

	$(document).ready(function(){
		var $subject = $('#subject');		
		
		$subject.on('change',function(){
			var subject = $(this).val();
			get_tree_data(subject);
		});

	})