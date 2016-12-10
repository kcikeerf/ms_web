//= require ztree/js/jquery.ztree.core
//= require ztree/js/jquery.ztree.excheck
//= require_self

function selected_nodes_tree(tree_selector, tree_nodes){
	//初始参数
	this.tree_selector = typeof tree_selector !== 'undefined' ? tree_selector : "";
	if(this.tree_selector){
		this.tree = $(tree_selector)
	}
	this.tree_nodes = typeof tree_nodes !== 'undefined' ? tree_nodes : "";
	// if(!this.tree || !this.tree_nodes){
	// 	return false;
	// }

	this.setting = {
		view: {
			// addHoverDom: null,
			// removeHoverDom: null,
			showLine: true,
			selectedMulti: false
		},
		check: {
			enable: false
		},
		data: {
			key: {
				children: null,
			},
			simpleData: {
				enable: true,
				idKey: "rid",
				pIdKey: "pid", //pid父节点唯一标识符属性名称
				rootPId: null
			}
		},
		callback: {
		},
		edit: {
			enable: false
		}
	};

	this.construct_tree = function(){
		$.fn.zTree.init(this.tree, this.setting, this.tree_nodes);
	};

	this.ztree_obj = function(){
		var tree_id = tree_selector.split("#")[1];
		return $.fn.zTree.getZTreeObj(tree_id);
	};

    this.get_checked_nodes = function(){
    	var result = [];
		var tree_obj = this.ztree_obj();
		if(tree_obj){
			var nodes_arr = tree_obj.getCheckedNodes();
			for(var i in nodes_arr){	
				var node = nodes_arr[i];
				result.push({
					name: node.name,
					rid: node.rid,
					pid: node.pid,
					uid: node.uid
				});
			}
		}
		return result;
    };

	this.get_last_nodes = function(){
		var result = [];
		var tree_obj = this.ztree_obj();
		if(tree_obj){
			var nodes_arr = tree_obj.getCheckedNodes();
			var pids = [];
			for(var i in nodes_arr){
				pids.push(nodes_arr[i].pid);
			}
			for(var i in nodes_arr){	
				var node = nodes_arr[i];
				if(pids.indexOf(node.rid) > -1){
					// do nothing
				}else{
					result.push({
						name: node.name,
						rid: node.rid,
						pid: node.pid,
						uid: node.uid
					});
				}
			}
		}
		return result;
	};

	this.init = function(){
		this.construct_tree();
	}
}