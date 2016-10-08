/*弹出框事件*/
$(document).on('ready page:load', function (){
	/*导入html-zTree文件*/
	var setting = {
	        view: {
	            selectedMulti: false,
	            showLine: true,
	            showIcon: false,
	            showTitle: true
	        },
	        check: {
	            enable: true,
	            chkStyle: 'checkbox',
	            radioType: "level",
	            chkboxType:{"Y": "s", "N": "s"}
	        },
	        data: {
                key:{
                    name: "name",
                    title:"title"
                },
                simpleData: {
                    enable: true,
                    idKey: "id",
                    pIdKey: "pid",
                    rootPId: null
                }
	        },
	        callback: {
	        	beforeCheck: zTreeBeforeCheck,
	        	onClick: zTreeOnClick,
	        	beforeDblClick: zTreeBeforeDblClick
	        }
	    }
	    $(document).on('modal:open',function(e,arr){
//		  	var $nodeUid = $("input#node_uid").val();
			var pap_uid = $("input#pap_uid").val();
		  	if(!$("#skill_tree").children().length){
		  		$.ajax({
					type:"GET",
					url:"/checkpoints/get_ckp_data",
					data: {'pap_uid':pap_uid},//{'node_uid':$nodeUid},//咱不做更改，只是用此参数
					async:true,
					success:function(data){
						uncheck(data);
						var zNodes_knowledge = data.knowledge;
						var zNodes_skill = data.skill;
						var zNodes_ability = data.ability;
						$.fn.zTree.init($("#knowledge_tree"), setting, zNodes_knowledge);
		                $.fn.zTree.init($("#skill_tree"), setting, zNodes_skill);
		                $.fn.zTree.init($("#ability_tree"), setting, zNodes_ability);
		                arr && update_data(arr);
					},
					error:function(){
						alert('失败');
					}
				});
		  	}else{
		  		arr && update_data(arr);
		  	}
		});	
	var uncheck=function(obj){
	    if(Object.prototype.toString.call(obj)=="[object Object]"){
	        for(var i in obj){
	            if(i=="nocheck")obj[i]=!!obj[i];
	            else if(Object.prototype.toString.call(obj[i])=="[object Object]" || Object.prototype.toString.call(obj[i])=="[object Array]"){
	            		uncheck(obj[i]);
	            }
	            
	        }
	    }else if(Object.prototype.toString.call(obj)=="[object Array]"){
	        for(var i=0,l=obj.length;i<l;i++){
	            if(Object.prototype.toString.call(obj[i])=="[object Object]" || Object.prototype.toString.call(obj[i])=="[object Array]"){
	            	uncheck(obj[i]);
	            }
	        }
	    }
	}
	function update_data(arr){
		var tabIndex = arr.tabIndex;
		$('#myTab li:eq('+tabIndex+') a').tab('show');
		var dataArr = arr.dataArr;
		var treeObj_knowledge = $.fn.zTree.getZTreeObj("knowledge_tree");
		var treeObj_skill = $.fn.zTree.getZTreeObj("skill_tree");
		var treeObj_ability = $.fn.zTree.getZTreeObj("ability_tree");
		treeObj_knowledge.checkAllNodes(false);
		treeObj_skill.checkAllNodes(false);
		treeObj_ability.checkAllNodes(false);
		var dataLen = (typeof(dataArr) == "undefined")? 0:dataArr.length;
		for(var i=0;i<dataLen;i++){
			if(dataArr[i].dimesion == "knowledge"){
				var nodes = treeObj_knowledge.getNodesByParam("uid", dataArr[i].uid);
				treeObj_knowledge.checkNode(nodes[0], true, false);
            }else if(dataArr[i].dimesion == "skill"){
                var nodes = treeObj_skill.getNodesByParam("uid", dataArr[i].uid);
				treeObj_skill.checkNode(nodes[0], true, false);
            }else if(dataArr[i].dimesion == "ability"){
                var nodes = treeObj_ability.getNodesByParam("uid", dataArr[i].uid);
				treeObj_ability.checkNode(nodes[0], true, false);
            }
		}
	}
	function zTreeOnClick(event, treeId, treeNode){
		var treeObj = $.fn.zTree.getZTreeObj(treeId);
		var Node = treeObj.getNodeByTId(treeNode.tId);
		var isPut = Node.open;
		var isCheck = Node.checked;
		var checkLenth = treeObj.getCheckedNodes(true).length;
		if(treeNode.isParent){
			if(isPut){
				treeObj.expandNode(Node, false, false, false,false);
			}else{
				treeObj.expandNode(Node, true, false, false,false);
			};
		}else{
			if(isCheck){
				treeObj.checkNode(Node, false, false);
			}else{
				if(treeId == 'knowledge_tree'){
			    	if(checkLenth >= 1){
			    		alert('知识指标限选一个考察点');
			    		return false;
			    	}else{
			    		treeObj.checkNode(Node, true, false);
			    	}
			    }else{
			    	if(checkLenth >= 2){
			    		alert('技能能力指标限选两个考察点');
			    		return false;
			    	}else{
			    		treeObj.checkNode(Node, true, false);
			    	}
			    }
			}
			
		}
	}
	function zTreeBeforeDblClick(treeId, treeNode) {
	    return false;
	};
	function zTreeBeforeCheck(treeId, treeNode) {
		var treeObj = $.fn.zTree.getZTreeObj(treeId);
		var checkLenth = treeObj.getCheckedNodes(true).length;
		var isOk = treeObj.getNodeByTId(treeNode.tId).getCheckStatus().checked;
		if(isOk){
			return true;
		}else{
			if(treeId == 'knowledge_tree'){
		    	if(checkLenth == 1){
		    		alert('知识指标限选一个考察点');
		    		return false;
		    	}
		    }else{
		    	if(checkLenth == 2){
		    		alert('技能能力指标限选两个考察点');
		    		return false;
		    	}
		    }
		}
	};
	//知识考察点添加到页面
	$(document).on("click", "#refer-btn", function(){
		var dataStr = [];
		// 知识
		var chk_value_knowledge = [];
		var chk_uid_knowledge = [];
		var $modal = $("#commonDialog");
		var treeObj_knowledge = $.fn.zTree.getZTreeObj("knowledge_tree");
		var nodes_knowledge = treeObj_knowledge.getCheckedNodes(true);
		var knowledge_len = nodes_knowledge.length;
		for(var i=0;i<knowledge_len;i++){
			var str = {
				"dimesion":"" + nodes_knowledge[i].dimesion + "", 
			    "checkpoint":""+nodes_knowledge[i].checkpoint+"",
			    "uid":""+nodes_knowledge[i].uid+"",
			    "ckp_source": ""+nodes_knowledge[i].ckp_source+""
			};
			dataStr.push(str);
		}
		//技能
		var chk_value_skill =[];
		var chk_uid_skill = [];
		var treeObj_skill = $.fn.zTree.getZTreeObj("skill_tree");
		var nodes_skill = treeObj_skill.getCheckedNodes(true);    
		var skill_len = nodes_skill.length;
		for(var i = 0 ;i<skill_len;i++){
			var str = {
				"dimesion":""+nodes_skill[i].dimesion+"",
				"checkpoint":""+nodes_skill[i].checkpoint+"",
				"uid":""+nodes_skill[i].uid+"",
				"ckp_source": ""+nodes_skill[i].ckp_source+""
			};
			dataStr.push(str);
		}
		//能力
		var chk_value_ability =[];	  
		var chk_uid_ability = [];
		var treeObj_ability = $.fn.zTree.getZTreeObj("ability_tree");
		var nodes_ability = treeObj_ability.getCheckedNodes(true); 
		var ability_len = nodes_ability.length;
		for(var i = 0 ;i<ability_len;i++){
			var str = {
				"dimesion":""+nodes_ability[i].dimesion+"",
				"checkpoint":""+nodes_ability[i].checkpoint+"",
				"uid":""+nodes_ability[i].uid+"",
				"ckp_source": ""+nodes_ability[i].ckp_source+""
			};
			dataStr.push(str);
		}
		var dataStr_len = dataStr.length;
		$(document).trigger("modal:close",{dataArr:dataStr});
	})
});




