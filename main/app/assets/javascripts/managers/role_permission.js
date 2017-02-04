//= require_self

function role_permission_list(list_selector, role_id, permission_type){
	//初始参数
	this.list_selector = typeof list_selector !== 'undefined' ? list_selector : "";
	if(this.list_selector){
		this.list = $(list_selector);
	}
	this.role_id = typeof role_id !== 'undefined' ? role_id : "";
	this.permission_type = typeof permission_type !== 'undefined' ? permission_type : "";

	this.api = {
		permission_list: "/managers/roles/" + this.role_id + "/permissions/list.json",
		api_permission_list: "/managers/roles/" + this.role_id + "/api_permissions/list.json",
		save_role_permission: "/managers/roles/" + this.role_id + "/combine_permissions",
		save_role_api_permission: "/managers/roles/" + this.role_id + "/combine_api_permissions",		
	};

	this.ajax = function(method, url, params, callback){
		var self = this;
		console.log(url);
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

	//读取角色权限列表
	this.get_permission_list = function(){
		var params = "";
		if(!this.api[this.permission_type+"_list"]){
			return [];
		}
		this.ajax("GET", this.api[this.permission_type+"_list"], params, this.check_permissions);
	};

	//角色的当前权限设定选择状态
	this.check_permissions = function(ins, data){
		var values = $.map(data, function(value, index){ return value.id;});
		console.log(values);
		ins.list.combobox('setValues', values);
	};

    //保存当前权限关联
    this.save_role_permissions = function(){
    	var selected_values = this.list.combobox("getValues");
    	console.log(this.list);
		var params = { 
			authenticity_token: $('meta[name="csrf-token"]')[0].content,
    		permission_ids: selected_values
    	};
    	this.ajax("POST", this.api["save_role_"+permission_type], params);
    };

	this.init = function(){
		this.get_permission_list();
	}
}