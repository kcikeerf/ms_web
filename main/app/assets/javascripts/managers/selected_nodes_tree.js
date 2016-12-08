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
	},

	this.init = function(){
		this.construct_tree();
	}
}