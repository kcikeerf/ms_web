//= require managers/node_structure_catalog
//= require managers/node_subject_checkpoints
//= require managers/selected_nodes_tree
//= require_self

function node_catalog_checkpoint_combination(node_uid,catalog_uids){
	this.node_uid = typeof node_uid !== 'undefined' ? node_uid : "";
	this.catalog_uids = typeof catalog_uids !== 'undefined' ? catalog_uids : [];

	//对象变量
	var self = this;
	this.selected_catalog_tree = null;
	this.knowledge_tree = null;
	this.skill_tree = null;
	this.ability_tree = null;
	this.selected_knowledge_tree = null;
	this.selected_skill_tree = null;
	this.selected_ability_tree = null;
	this.combination_data = {
		authenticity_token: $('meta[name="csrf-token"]')[0].content, //session token
		node_uid: null,
		catalogs: [],
		checkpoints: {
			knowledge: [],
			skill: [],
			ability: []
		}
	};
	this.api = {
		combine_node_catalogs_subject_checkpoints: {
			method: "POST",
			url: "/managers/checkpoints/combine_node_catalogs_subject_checkpoints"
		},
		catalog_checkpoints: {
			method: "POST",
			url: "/managers/checkpoints/list"
		}
	};

	this.node_checked_func_core = function(tree_selector, data){
		var obj = new selected_nodes_tree(tree_selector, data);
		obj.init();
		return obj;
	};

	//初始化教材目录
	this.manager_textbook_catalog = new textbook_catalog(
			null, 
			"managers_node_structures_list",
			this.node_uid,
			"managers_node_structure_catalogs_ztree", 
			catalog_uids,
			//回调函数
			[
				//更新选择树
				{	
					func: function(tree_node, data){
						self.selected_catalog_tree = self.node_checked_func_core("#managers_selected_catalogs_tree", data);
					}
				},
				//更新指标树
				{
					func: function(treeNode, checked_nodes){
						$.ajax({
							url: self.api.catalog_checkpoints.url,
							type: self.api.catalog_checkpoints.method,
							data: { 
								authenticity_token: $('meta[name="csrf-token"]')[0].content, //session token
								node_catalog_ids: $.map(checked_nodes, function(value, index){return value.uid}) 
							},
							dataType: "json",
							success: function(data){
								var flag = true;//treeNode.checked;
								self.knowledge_tree.check_nodes(data.knowledge, flag);
								self.skill_tree.check_nodes(data.skill,flag);
								self.ability_tree.check_nodes(data.ability,flag);
							},
							error: function(data){
								// do nothing
							}
						});
					}
				}
			]
		);

	//目录指标关联按钮
	this.managers_catalog_checkpoint_combination_button = $(".managers_catalog_checkpoint_combination_button");
	this.managers_catalog_checkpoint_combination_button.bind('click', function(){
		//获取选择目录及指标
		self.combination_data.node_uid = self.manager_textbook_catalog.textbook.checked_uid;
		self.combination_data.catalogs = self.selected_catalog_tree.get_checked_nodes();
		self.combination_data.checkpoints.knowledge = self.selected_knowledge_tree.get_checked_nodes();
		self.combination_data.checkpoints.skill = self.selected_skill_tree.get_checked_nodes();
		self.combination_data.checkpoints.ability = self.selected_ability_tree.get_checked_nodes();

		//
		$.ajax({
			url: self.api.combine_node_catalogs_subject_checkpoints.url,
			type: self.api.combine_node_catalogs_subject_checkpoints.method,
			data: self.combination_data,
			dataType: "json",
			success: function(data){
				self.init();
			},
			error: function(data){
				// do nothing
			}
		});
	});

	this.init = function(){
		// var self = this;
		//清空已选择目录
		this.manager_textbook_catalog.textbook.after_change.push({
			func: function(){
				self.selected_catalog_tree = self.node_checked_func_core("#managers_selected_catalogs_tree", []);
			}
		});

		//更新教材后的指标相关的对象
		this.manager_textbook_catalog.textbook.after_change.push({
			func: function(){
				//初始化知识树
				self.knowledge_tree = new subject_checkpoint(
						"#managers_subejct_ckp_knowledge_tree", 
						self.manager_textbook_catalog.textbook.checked_item.subject, 
						self.manager_textbook_catalog.textbook.checked_item.xue_duan, 
						"knowledge", 
						null,
						{
			    			node_checked: function(data){
			    				self.selected_knowledge_tree = self.node_checked_func_core("#managers_selected_subejct_ckp_knowledge_tree", data);
			    			}
			    		}
					);
				self.knowledge_tree.init();
				//清空已选择知识树
				self.selected_knowledge_tree = self.node_checked_func_core("#managers_selected_subejct_ckp_knowledge_tree", []);

				//初始化技能树
				self.skill_tree = new subject_checkpoint(
						"#managers_subejct_ckp_skill_tree", 
						self.manager_textbook_catalog.textbook.checked_item.subject, 
						self.manager_textbook_catalog.textbook.checked_item.xue_duan, 
						"skill", 
						null,
						{
			    			node_checked: function(data){
			    				self.selected_skill_tree = self.node_checked_func_core("#managers_selected_subejct_ckp_skill_tree", data);
			    			}
			    		}
					);
				self.skill_tree.init();
				//清空已选择技能树
				self.selected_skill_tree = self.node_checked_func_core("#managers_selected_subejct_ckp_skill_tree", []);

				//初始化能力树
				self.ability_tree = new subject_checkpoint(
						"#managers_subejct_ckp_ability_tree", 
						self.manager_textbook_catalog.textbook.checked_item.subject, 
						self.manager_textbook_catalog.textbook.checked_item.xue_duan, 
						"ability", 
						null,
						{
			    			node_checked: function(data){
			    				self.selected_ability_tree = self.node_checked_func_core("#managers_selected_subejct_ckp_ability_tree", data);
			    			}
			    		}
					);
				self.ability_tree.init();
				//清空已选择能力树
				self.selected_ability_tree = self.node_checked_func_core("#managers_selected_subejct_ckp_ability_tree", []);
			}
		});
		this.manager_textbook_catalog.init();	
	}
}