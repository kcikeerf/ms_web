//= require managers/selected_nodes_tree
//= require_self

function node_catalog_checkpoints_display(tree_selectors, data){
	this.data = typeof data !== 'undefined' ? data : {knowledge:[],skill:[],ability:[]};
	this.init = function(){
		var knowledge_tree = new selected_nodes_tree(tree_selectors.knowledge, this.data.knowledge.nodes);
		knowledge_tree.init();
		var skill_tree = new selected_nodes_tree(tree_selectors.skill, this.data.skill.nodes);
		skill_tree.init();
		var ability_tree = new selected_nodes_tree(tree_selectors.ability, this.data.ability.nodes);
		ability_tree.init();		
	}
}