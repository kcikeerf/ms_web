class BankSubjectCheckpointCkp < ActiveRecord::Base
	self.primary_key = 'uid'

	#concerns
	include TimePatch
	include InitUid

  has_many :bank_nodestructure_subject_ckps, foreign_key: 'subject_ckp_uid', dependent: :destroy
  has_many :bank_nodestructures, through: :bank_nodestructure_subject_ckps
  has_many :bank_nodestructure_subject_ckps, foreign_key: 'subject_ckp_uid', dependent: :destroy
  has_many :bank_node_catalogs, through: :bank_nodestructure_subject_ckps

	scope :not_equal_rid, ->(rid) { where.not(rid: rid) }
	scope :by_subject, ->(subject) { where(subject: subject) }
  scope :by_dimesion, ->(dimesion) { where(dimesion: dimesion) }
	scope :is_entity, -> { where(is_entity: true) }

	class << self

    #前端获取指标
    def get_web_ckps(params)
      Common::CheckpointCkp.ckp_types_loop {|dimesion| get_ckps_by_dimesion(params, dimesion) }
    end

		def get_ckps_by_dimesion(params, dimesion)
      level_config = Common::CheckpointCkp::LevelArr.clone
			nodes = root_node(dimesion)
			nodes[:children] = []

			# node_structure = BankNodestructure.find(node_uid)
			#all_nodes = node_structure.bank_subject_checkpoint_ckps.where(dimesion: dimesion)
      target_subject, target_category = BankCheckpointCkp.get_subject_ckp_params params
      dim_all_nodes = self.where(:subject => target_subject, :category => target_category, :dimesion => dimesion)
		
			node_level_first = level_config.first
			first_level_nodes = get_nodes_by_rid_length(dim_all_nodes, node_level_first)

			level_config.delete(node_level_first)
			first_level_nodes.each {|node| nodes[:children] << build_nodes(dim_all_nodes, node, level_config) }

			[nodes]
		end

		def build_nodes(nodes, old_node, level_config)
      lv_arr = level_config.clone
			return_node = old_node.organization_hash
			return_node[:children] = []
			lv_arr.each do |l|
        next if (l.first - 1) * Common::SwtkConstants::CkpStep > old_node.rid.size

        need_nodes = get_nodes_by_rid_length(nodes, l).select {|n| n.rid.match(/^#{old_node.rid}/) }
        entity_arr = need_nodes.select{|n| n.is_entity }

        need_nodes.to_a.each do |node|
          lv_arr.delete(l)
        	node_h = build_nodes(nodes, node, lv_arr)
        	return_node[:children] << node_h
        end
        return return_node if entity_arr.size == need_nodes.size  #退出，全是末级节点
      end
	    return_node
	  end

    def get_nodes_by_rid_length(nodes, node_level)
    	node_level, data = node_level.clone, []
    	if node_level.size > 1
    		start_rid_length = (node_level[0] || 0) * Common::SwtkConstants::CkpStep
    		end_rid_length = (node_level[1] || 0) * Common::SwtkConstants::CkpStep
    		# nodes.where("length(rid) between ? and ?", start_rid_length, end_rid_length)
    		nodes.select {|n| n.rid.length.between?(start_rid_length, end_rid_length) }
    	else
    		# nodes.where("length(rid) = ?", node_level.first * Common::SwtkConstants::CkpStep)
    		nodes.select {|n| n.rid.length == node_level.first * Common::SwtkConstants::CkpStep}
    	end
    end

    #后台指标读取
    def get_all_ckps(subject, xue_duan, str_pid='')
      Common::CheckpointCkp.ckp_types_loop {|dimesion| get_all_ckps_by_dimesion(subject, xue_duan, dimesion, str_pid) }
    end

    # get all nodes include pid
    #  
    # str_pid: parent rid
    # node_uid: node structure uid
    # dimesion
    def get_all_ckps_by_dimesion(subject, xue_duan, dimesion, str_pid='', options={})
      result = {pid: str_pid, nodes: []}
      return result if (subject.blank? || dimesion.blank?)
      
      ckps = where(subject: subject,category: xue_duan, dimesion: dimesion).order({rid: :asc})
      unless str_pid.blank?
	      ckp = ckps.find_by(uid: str_pid)
	      ckps = ckp ? ckp.children : []
	    end
      # ckps = BankRid.get_all_child target_objs, pid
      result[:nodes] = constructure_ckps(ckps, options)
      result[:nodes].unshift(root_node(dimesion, options))
      return result
    end

    # 
    # str_pid: parent rid
    # node_uid: node structure uid
    #
    def save_ckp params
      subject = params[:subject]
      category = params[:category]
    	return nil if subject.blank? || params[:category].blank?

    	target_objs = where(subject: subject, category: category)
    	new_rid = BankRid.get_new_rid target_objs, params[:str_pid]

    	new_ckp = self.new(dimesion: params[:dimesion], 
    		rid: new_rid, 
    		subject: subject,
        category: params[:category],
    		checkpoint: params[:checkpoint], 
    		desc: params[:desc],
        advice: params[:advice],
        weights: params[:weights],
        sort: new_rid,
    		is_entity: true)                 

    	rid_len = new_rid.size

    	ckp_parent_node = target_objs.where(rid: new_ckp.parent_node_rid).first if rid_len > Common::SwtkConstants::CkpStep

    	transaction do
    		new_ckp.save!
    		ckp_parent_node.update(is_entity: false) if ckp_parent_node
    	end
    	return new_ckp.organization_hash
    end

    def ckps_group(ckps, child_ckp_uids = [])
    	knowledge, skill, ability = [root_node('knowledge')], [root_node('skill')], [root_node('ability')]

	    ckps.each do |c|
	    	ckp_hash =  c.organization_hash
        ckp_hash.delete(:nocheck)
	    	ckp_hash[:checked] = true if child_ckp_uids.include?(c.uid)
	      knowledge << ckp_hash if c.dimesion == 'knowledge'
	      skill << ckp_hash if c.dimesion == 'skill'
	      ability << ckp_hash if c.dimesion == 'ability'
	    end
	    {knowledge: knowledge, skill: skill, ability: ability}
    end

    # 循坏生成指标
    def generate_ckp(subject, dimesion, ckp_arr, parent_rid = nil)
      ckp_arr.each do |ckp|
        ckp.symbolize_keys!
        name = ckp[:text]
        new_ckp = save_ckp(subject: subject, checkpoint: name, dimesion: dimesion, str_pid: parent_rid)
        ckp_children = ckp[:items]
        unless ckp_children.blank?
          generate_ckp(subject, dimesion, ckp_children, new_ckp[:rid])
        end
      end
    end

    def root_node(dimesion, options={})
      nocheck = options[:disable_no_check].nil?? 1 : options[:disable_no_check]
    	# {rid: '', pid: '', nocheck: nocheck, dimesion: dimesion, name: Common::Locale::i18n('managers.root_node'), open: true}
      {rid: '', pid: '', nocheck: nocheck, dimesion: dimesion, name: Common::Locale::i18n("dict.#{dimesion}") + Common::Locale::i18n('managers.root_node'), open: true}
    end

    def constructure_ckps ckps, options={}
      ckps.map{|item| item.organization_hash(options)}
      # ckps.map(&:organization_hash)
    end
	end

	#
  # str_uid: current check point uid 
  # str_pid: parent rid
  # node_uid: node structure uid
  #
  #
  def update_ckp params
    ckp_hash = params.extract!(:checkpoint, :desc, :advice, :weights)
  	update(ckp_hash)

  	return organization_hash
  end

  def move_node(move_to_parent_uid)
  	nodes = self.class.where(subject: subject)
  	old_parent_node = parent

  	parent_node = nodes.find(move_to_parent_uid) unless move_to_parent_uid.blank?
  	children_nodes = children

  	new_rid = BankRid.get_new_rid(nodes, parent_node.try(:rid))
  	transaction do 
  		update(rid: new_rid)
  		parent_node.update(is_entity: false) if parent_node && parent_node.is_entity

  		children_nodes.each do |child_node|
  			rid = BankRid.get_new_rid(nodes, new_rid)
  			child_node.update(rid: rid)
  		end

  		old_parent_node.update(is_entity: true) if old_parent_node && old_parent_node.children.blank?
  	end
  	return true
  end


  def children
  	get_nodes(rid.size, rid, subject, dimesion, category).not_equal_rid(rid)
  end

  # def parents
  # 	get_nodes(Common::SwtkConstants::CkpStep, parent_node_rid, subject, dimesion, category).not_equal_rid(rid)
  # end

  def parent
  	get_nodes(parent_node_rid.size, parent_node_rid, subject, dimesion, category).find_by(rid: parent_node_rid)
  end

  def parent_node_rid
  	rid.slice(0, rid.size - Common::SwtkConstants::CkpStep)
  end

  def organization_hash options={}
    nocheck_flag = options[:disable_no_check].nil?? is_entity^1 : options[:disable_no_check]
    { 
      id: rid, 
      uid: uid,
      rid: rid,
      pid: rid.slice(0, ((rid.size - 3 < 0) ? 0 :(rid.size - 3))),
      dimesion: dimesion,
      checkpoint: checkpoint,
      name: checkpoint,
      weights: weights,
      title: desc.blank?? checkpoint : desc,
      is_entity: is_entity,
      advice: advice,
      desc: desc,
      sort: sort,
      ckp_source: Common::CheckpointCkp::CkpSource::SubjectCkp,
      nocheck: nocheck_flag,
      chkDisabled: false
    }
  end

  # 获取所属指标体系全部指标包括自己
  #
  def families
    ( subject.nil? || category.nil? )? [] : self.class.where(subject: subject, category: category)
  end

  private

  def get_nodes(length, rid, subject, dimesion, category)
  	self.class.where('subject = ? and dimesion = ? and category = ? and left(rid, ?) = ?', subject, dimesion, category, length, rid)
  end 

  def delete_children
  	children_nodes = children
  	parent_node = parent
  	parent_node.update(is_entity: true) if parent_node && parent_node.children.blank?

  	return false if children_nodes.blank?
  	children.destroy_all
  end
  
end
