//= require ztree/js/jquery.ztree.core
//= require ztree/js/jquery.ztree.excheck
//= require_self

function textbook(textbook_form_id, textbook_select_list_id, textbook_checked_uid){
	//初始化
	this.form_id = typeof textbook_form_id !== 'undefined' ? textbook_form_id : null;
	if(this.form_id){
		this.form = $("#" + this.form_id);
	}
	this.select_list_id = typeof textbook_select_list_id !== 'undefined' ? textbook_select_list_id : null;
	if(this.select_list_id){
		this.select_list = $("#" + this.select_list_id);
	}
	this.checked_uid = typeof textbook_checked_uid !== 'undefined' ? textbook_checked_uid : null;
	this.checked_item = null;

	this.api = {
		textbook_list: "/node_structures/list"
	};

	this.after_change = [];

	this.bind_event = function(){
		var self = this;
		this.select_list.combobox({
			onChange: function(){
				self.checked_uid = self.select_list.combobox("getValue");
				checked_index = self.select_list.combobox("getData").findIndex(function(x){ return x.uid == self.checked_uid });
				self.checked_item = self.select_list.combobox("getData")[checked_index];
				//获取教材目录
				for( var item in self.after_change ){
					self.after_change[item].func();
				};
				//this.catalog.get_list();
			}
		});
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
	//读取教材列表
	this.get_list = function(){
		var params = ""
		if(this.form){
			params = this.form.serialize();
		}
		this.ajax("GET", this.api.textbook_list, params, this.update_select_list);
	};

	//更新教材select列表
	this.update_select_list = function(ins, data){
		ins.select_list.combobox("loadData", data);
		if(ins.checked_uid){
			setTimeout(function(){ins.select_list.combobox("select", ins.checked_uid)}, 1000);
		}
		ins.bind_event();
	};
}

function catalog(textbook_uid, catalog_tree_id, catalog_checked_uids, callback_arr){
	var self = this;
	this.textbook_uid = typeof textbook_uid !== 'undefined' ? textbook_uid : null;
	this.tree_id = typeof catalog_tree_id !== 'undefined' ? catalog_tree_id : null;
	if(this.tree_id){
		this.tree = $("#" + this.tree_id);
	}
	this.checked_uids = typeof catalog_checked_uids !== 'undefined' ? catalog_checked_uids : [];
	this.callback_arr = typeof callback_arr !== 'undefined' ? callback_arr : [];
	this.tree_data = [];
	this.checked_nodes = [];

	this.api = {
		catalog_list: "/node_structures/catalog_list"
	};

	//当节点被选择的时候
	this.node_checked = function(event, treeId, treeNode){
		tree_obj = $.fn.zTree.getZTreeObj(treeId);
		self.checked_nodes = tree_obj.getCheckedNodes();
		for( var item in self.callback_arr ){
			self.callback_arr[item].func(treeNode, self.checked_nodes);
		};		
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
	this.ztree_obj = function(){
		return $.fn.zTree.getZTreeObj(this.tree_id);
	};
	//读取目录列表
	this.get_list = function(){
		var params = ""
		if(this.textbook_uid){
			params = "id=" + this.textbook_uid;
		}
		this.ajax("GET", this.api.catalog_list, params, this.construct_tree);
	};
	//构建目录树
	this.construct_tree = function(ins, data){
		$.fn.zTree.init(ins.tree, ins.setting, data);
		console.log()
		for(var i in self.checked_uids){
			console.log(self.checked_uids[i]);
			var target_node = self.ztree_obj().getNodeByParam("uid", self.checked_uids[i], null);
			console.log(target_node);
			self.ztree_obj().checkNode(target_node, true, true);
			//this.ztree_obj().expandNode(target_node, true, false, false);
		}
	};

}

function textbook_catalog(textbook_form_id, textbook_select_list_id, textbook_checked_uid,catalog_tree_id, catalog_checked_uids, callback_arr){ // 教材过滤组件begin
	var self = this;
	self.textbook = new textbook(textbook_form_id, textbook_select_list_id, textbook_checked_uid);
	var callback_h = {
		func: function(){
			self.catalog = new catalog(self.textbook.checked_uid, catalog_tree_id, catalog_checked_uids, callback_arr);
			self.catalog.get_list();
		}
	};
	self.textbook.after_change.push(callback_h);

	self.init = function(){
		self.textbook.get_list();
	}
} // 教材过滤组件定义end