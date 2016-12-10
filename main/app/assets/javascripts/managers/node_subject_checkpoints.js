//= require ztree/js/jquery.ztree.core
//= require ztree/js/jquery.ztree.excheck
//= require_self

function subject_checkpoint(tree_selector, subject, xue_duan, dimesion, checked_ckp_uids, callback_obj){
	var self = this;
	//初始参数
	this.tree_selector = typeof tree_selector !== 'undefined' ? tree_selector : "";
	if(this.tree_selector){
		this.tree = $(tree_selector)
	}
	this.subject = typeof subject !== 'undefined' ? subject : "";
	this.xue_duan = typeof xue_duan !== 'undefined' ? xue_duan : "";
	this.dimesion = typeof dimesion !== 'undefined' ? dimesion : "";
	this.checked_ckp_uids = typeof checked_ckp_uids !== 'undefined' ? checked_ckp_uids : [];
	this.callback_obj = typeof callback_obj !== 'undefined' ? callback_obj : {};

	//当节点被选择的时候
	this.node_checked = function(event, treeId, treeNode){
		tree_obj = $.fn.zTree.getZTreeObj(treeId);
		self.checked_nodes = tree_obj.getCheckedNodes();
		for(var i in self.checked_nodes){
			self.checked_nodes[i].open=true;
		}
		callback_obj.node_checked(self.checked_nodes);
	};

	this.setting = {
		view: {
			// addHoverDom: null,
			// removeHoverDom: null,
			showLine: true,
			selectedMulti: true
		},
		check: {
			enable: true,
			chkStyle: 'checkbox',
			chkboxType: { "Y": "p", "N": "ps" },
			radioType: "level",
			autoCheckTrigger: true
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
			onCheck: this.node_checked
		},
		edit: {
			enable: false
		}
	};

	this.api = {
		subject_checkpoints_list: "/subject_checkpoints/ztree_data_list"
	};

	this.ajax = function(method, url, params, callback){
		var self = this;
		$.ajax({
			url: url,
			type: method,
			data: params,
			dataType: "json",
			success: function(data){
				if(callback){
					callback(self, data);
				}
			},
			error: function(data){
				// do nothing
			}
		});
	};

	this.get_list = function(){
		var params = ""
		if(this.subject && this.xue_duan && this.dimesion){
			params = "subject=" + this.subject + "&"
				+ "xue_duan=" + this.xue_duan + "&"
				+ "dimesion=" + this.dimesion;
		} else {
			return false;
		}
		this.ajax("GET", this.api.subject_checkpoints_list, params, this.construct_tree);
	};

	this.construct_tree = function(ins, data){
		$.fn.zTree.init(ins.tree, ins.setting, data.nodes);
	};

	this.ztree_obj = function(){
		var tree_id = tree_selector.split("#")[1];
		return $.fn.zTree.getZTreeObj(tree_id);
	};

	this.check_nodes = function(nodes,flag){
		var checked_nodes = this.ztree_obj().getCheckedNodes();
		for(var i in checked_nodes){
			this.ztree_obj().checkNode(checked_nodes[i],false);
		}
		for(var i in nodes){
			var node = nodes[i];
			var target_node = this.ztree_obj().getNodeByParam("uid", node.uid, null);
			this.ztree_obj().checkNode(target_node, flag, true);
			//this.ztree_obj().expandNode(target_node, true, false, false);
		}
	};

	this.init = function(){
		this.get_list();
	}
}