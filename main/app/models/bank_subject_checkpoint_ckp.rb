class BankSubjectCheckpointCkp < ActiveRecord::Base
  self.primary_key = 'uid'

  #concerns
  include TimePatch
  include InitUid

  belongs_to :checkpoint_system, foreign_key: "checkpoint_system_rid", class_name: "CheckpointSystem"
  
  has_many :bank_nodestructure_subject_ckps, foreign_key: 'subject_ckp_uid', dependent: :destroy
  has_many :bank_nodestructures, through: :bank_nodestructure_subject_ckps
  has_many :bank_nodestructure_subject_ckps, foreign_key: 'subject_ckp_uid', dependent: :destroy
  has_many :bank_node_catalogs, through: :bank_nodestructure_subject_ckps

  before_save :set_subject, :set_xue_duan, :set_dimesion
  
  scope :not_equal_rid, ->(rid) { where.not(rid: rid) }
  scope :by_subject, ->(subject) { where(subject: subject) }
  scope :by_dimesion, ->(dimesion) { where(dimesion: dimesion) }
  scope :is_entity, -> { where(is_entity: true) }

  class << self

    #前端获取指标
    def get_web_ckps(params)
      checkpoint_system_rid = params[:checkpoint_system_rid] || "000"
      checkpoint_system = CheckpointSystem.where(rid: checkpoint_system_rid).first
      if checkpoint_system.present? && checkpoint_system.sys_type == "xy_default"
        Common::CheckpointCkp.ckp_types_loop {|dimesion| get_ckps_by_dimesion(params, dimesion,checkpoint_system_rid) }
      else
        get_ckps_by_dimesion(params, "other", checkpoint_system_rid)
      end
    end

    def get_ckps_by_dimesion(params, dimesion, checkpoint_system_rid)
      level_config = Common::CheckpointCkp::LevelArr.clone
      nodes = root_node(dimesion)
      nodes[:children] = []

      # node_structure = BankNodestructure.find(node_uid)
      #all_nodes = node_structure.bank_subject_checkpoint_ckps.where(dimesion: dimesion)
      target_subject, target_category = BankCheckpointCkp.get_subject_ckp_params params
      dim_all_nodes = self.where(:subject => target_subject, :category => target_category, :dimesion => dimesion,  :checkpoint_system_rid => checkpoint_system_rid)
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

    def get_all_ckps_plus(subject,xue_duan,system_id='000', str_pid='')
      checkpoint_system = CheckpointSystem.where(rid: system_id).first
      if checkpoint_system.present? && checkpoint_system.sys_type == "xy_default"
        Common::CheckpointCkp.ckp_types_loop {|dimesion| get_all_ckps_by_dimesion_plus(subject, xue_duan, system_id, dimesion, str_pid) }
      else
        get_all_ckps_by_dimesion_plus(subject, xue_duan, system_id, "other", str_pid)
      end
    end

    def get_all_ckps_by_dimesion_plus(subject, xue_duan, system_id, dimesion, str_pid='', options={})
      result = {pid: str_pid, nodes: []}
      return result if (subject.blank? || dimesion.blank?)

      ckps = where(subject: subject,category: xue_duan, checkpoint_system_rid: system_id, dimesion: dimesion).order({rid: :asc})
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
      dimesion = params[:dimesion]
      checkpoint_system_rid = params[:checkpoint_system_rid] || "000"
      return nil if subject.blank? || params[:category].blank? || dimesion.blank?
      
      target_objs = where(subject: subject, category: category, dimesion: dimesion, checkpoint_system_rid: checkpoint_system_rid)
      new_rid = BankRid.get_new_bank_rid target_objs, params[:str_pid]

      if new_rid.present?
        new_ckp = self.new(dimesion: params[:dimesion],
                           rid: new_rid,
                           subject: subject,
                           category: params[:category],
                           checkpoint: params[:checkpoint],
                           desc: params[:desc],
                           advice: params[:advice],
                           weights: params[:weights],
                           sort: new_rid,
                           high_level: params[:high_level],
                           checkpoint_system_rid: checkpoint_system_rid,
                           is_entity: true)

        rid_len = new_rid.size

        ckp_parent_node = target_objs.where(rid: new_ckp.parent_node_rid).first if rid_len > Common::SwtkConstants::CkpStep

        transaction do
          new_ckp.save!
          ckp_parent_node.update(is_entity: false) if ckp_parent_node
        end
        if ckp_parent_node 
          return [new_ckp.organization_hash, ckp_parent_node.organization_hash]
        else
          return [new_ckp.organization_hash,{}]
        end
      else
        return nil
      end
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
    def generate_ckp(subject, dimesion, ckp_arr, system_id="000", parent_rid = nil)
      ckp_arr.each do |ckp|
        ckp.symbolize_keys!
        name = ckp[:text]
        new_ckp = save_ckp(subject: subject, checkpoint: name, dimesion: dimesion, checkpoint_system_rid: system_id, str_pid: parent_rid)
        ckp_children = ckp[:items]
        unless ckp_children.blank?
          generate_ckp(subject, dimesion, ckp_children, system_id, new_ckp[:rid])
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

    # 获取影响范围
    # [参数]
    # 开始节点，不包含的节点
    # [返回值]
    # 受影响的节点的uid集合
    def common_influence_area(begin_node, not_include_node=nil)
      cond_str = " SUBSTRING(rid,?,?) >= ?"
      if begin_node.parent.present?
        nodes = begin_node.parent.children
      else
        nodes = where(subject: begin_node.subject, category: begin_node.category, dimesion: begin_node.dimesion, checkpoint_system_rid: begin_node.checkpoint_system_rid)
      end
      if not_include_node.present?
        cond_str += "AND SUBSTRING(rid, 1, ?) <> ?" 
        infilence_area = nodes.where(cond_str,  begin_node.rid.size - Common::SwtkConstants::CkpStep + 1, Common::SwtkConstants::CkpStep, begin_node.bank_node_rid, not_include_node.rid.size, not_include_node.rid)
      else
        infilence_area = nodes.where(cond_str,  begin_node.rid.size - Common::SwtkConstants::CkpStep + 1, Common::SwtkConstants::CkpStep, begin_node.bank_node_rid).order("rid ASC")
      end
      return infilence_area.map(&:uid)
    end

    # 压缩节点
    # [参数]
    #  学科，学段，三维
    # [返回值]
    # 压缩成功(0)/不需要压缩(1)/压缩失败(-1)
    def compress_node(subject, category, dimesion)
      regexp = Regexp.new("." * Common::SwtkConstants::CkpStep)
      nodes = where(subject: subject, category: category, dimesion: dimesion)
      node =  nodes.select {|node| node if node.rid.gsub(regexp).to_a.include?("zzz")}
      if node.present?
        parent_node = node[0].parent
        need_change_children = parent_node.children.order("rid ASC")
        need_change_children_step_rid = need_change_children.map {|ch| ch.rid.slice(parent_node.rid.size, Common::SwtkConstants::CkpStep)}
        need_change_children_step_rid.uniq!
        hash_bank_index = {}
        need_change_children_step_rid.each_with_index do |key, value|
          hash_bank_index[key] = value
        end
        transaction do
          begin
            need_change_children.each do |child|
              new_rid =child.replace_rid_from_hash(parent_node.rid, hash_bank_index)
              child.update(rid: new_rid)
            end            
          rescue Exception => e
            return -1
          end
        end
        return 0        
      else
        return 1
      end
    end
  end

  #
  # 类方法结束 实例方法开始 
  #

  # 根据hash中的关系替换部分bank_rid
  # [参数]
  # 需要替换的那一级的parent_rid, 相关的hash
  # [返回值]
  # 新的rid
  def replace_rid_from_hash(parent_node_rid,node_rid_hash)
    child_parent_rid, self_old_bank_id, children_bank_id = gsub_with_parent_rid(parent_node_rid)
    self_new_bank_id = node_rid_hash[self_old_bank_id].to_s(36).rjust(3, '0')
    new_rid = child_parent_rid + self_new_bank_id + children_bank_id
    return new_rid
  end

  # 按照parent_rid分割rid 分割为3个片段, parent_rid, old_bank_rid, children_rid
  # [参数]
  # 分割的parent_rid
  # [返回值]
  # parent_rid, old_bank_rid, children_rid
  def gsub_with_parent_rid(parent_node_rid)
    child_parent_rid = rid.slice(0,parent_node_rid.size)
    self_old_bank_id = rid.slice(child_parent_rid.size, Common::SwtkConstants::CkpStep)
    children_bank_id = rid.slice((child_parent_rid.size + Common::SwtkConstants::CkpStep)..-1)
    return child_parent_rid, self_old_bank_id, children_bank_id   
  end

  #
  # 类方法结束 实例方法开始 
  #

  # 根据hash中的关系替换部分bank_rid
  # [参数]
  # 需要替换的那一级的parent_rid, 相关的hash
  # [返回值]
  # 新的rid
  def replace_rid_from_hash(parent_node_rid,node_rid_hash)
    child_parent_rid, self_old_bank_id, children_bank_id = gsub_with_parent_rid(parent_node_rid)
    self_new_bank_id = node_rid_hash[self_old_bank_id].to_s(36).rjust(3, '0')
    new_rid = child_parent_rid + self_new_bank_id + children_bank_id
    return new_rid
  end

  # 按照parent_rid分割rid 分割为3个片段, parent_rid, old_bank_rid, children_rid
  # [参数]
  # 分割的parent_rid
  # [返回值]
  # parent_rid, old_bank_rid, children_rid
  def gsub_with_parent_rid(parent_node_rid)
    child_parent_rid = rid.slice(0,parent_node_rid.size)
    self_old_bank_id = rid.slice(child_parent_rid.size, Common::SwtkConstants::CkpStep)
    children_bank_id = rid.slice((child_parent_rid.size + Common::SwtkConstants::CkpStep)..-1)
    return child_parent_rid, self_old_bank_id, children_bank_id   
  end

  # str_uid: current check point uid
  # str_pid: parent rid
  # node_uid: node structure uid
  #
  #
  def update_ckp params
    ckp_hash = params.extract!(:checkpoint, :desc, :advice, :weights, :high_level)
    update(ckp_hash)

    return organization_hash
  end

  # 节点移动
  # [参数]
  # move_type: "inner", "prev", "next"
  # target_node_uid: 目标节点
  # [返回值]
  # true/false
  # [功能]
  # 将原节点移动到目标节点的指定类型里面，同时更新目标节点(可能包含目标节点）之后的节点, （替换目标节点，并更改子节点）
  def move_node(move_type, target_node_uid)
    nodes = self.class.where(subject: subject, category: category, dimesion: dimesion, checkpoint_system_rid: checkpoint_system_rid)
    target_node = nodes.find(target_node_uid) if target_node_uid.present?
    children_nodes = children.map(&:uid)
    old_rid = rid.clone
    old_parent_node = self.parent
    transaction do
      #old_parent_node_rid = parent.try(:rid)
      case move_type
      when "inner"
        parent_node = target_node
        new_rid = BankRid.get_new_bank_rid(nodes, target_node.try(:rid))
        #old_infilence_area = self.get_next_node.present? ? self.class.common_influence_area(self.get_next_node) : []
        fresh_parent_node_rid = target_node.try(:rid)
        fresh_infilence_area = []
      when "prev" 
        parent_node = target_node.parent
        new_rid = target_node.rid
        fresh_parent_node_rid = target_node.parent.try(:rid)      
        if parent_node == old_parent_node
          #old_infilence_area = self.class.common_influence_area(self.get_next_node)
          #old_infilence_area = self.get_next_node.present? ? self.class.common_influence_area(self.get_next_node, self) : []  
          fresh_infilence_area = self.class.common_influence_area(target_node, self)
        else
          #old_infilence_area = self.get_next_node.present? ? self.class.common_influence_area(self.get_next_node) : [] 
          fresh_infilence_area = self.class.common_influence_area(target_node)
        end
      when "next"
        return false if target_node.bank_node_rid == "zzz"
        parent_node = target_node.parent
        new_rid = target_node.get_next_node.present? ? target_node.get_next_node.rid : BankRid.get_new_bank_rid(nodes, target_node.parent.try(:rid))
        fresh_parent_node_rid = target_node.parent.try(:rid)      
        if parent_node == old_parent_node
          #old_infilence_area = self.get_next_node.present? ? self.class.common_influence_area(self.get_next_node, self) : []
          fresh_infilence_area = target_node.get_next_node.present? ? self.class.common_influence_area(target_node.get_next_node,self) : []
        else
          #old_infilence_area = self.get_next_node.present? ? self.class.common_influence_area(self.get_next_node) : []
          fresh_infilence_area = target_node.get_next_node.present? ? self.class.common_influence_area(target_node.get_next_node) : []        
        end
      end

      # if old_infilence_area.present? && self.class.find(old_infilence_area.first).bank_node_rid != "000"
      #   old_infilence_area.each do |old_node_uid|
      #     old_node = self.class.find(old_node_uid)
      #     old_node.change_infilence_node(old_parent_node_rid, "move_up")
      #   end
      # else
      #   #调用压缩
      # end
      if fresh_infilence_area.present? && self.class.find(fresh_infilence_area.last).bank_node_rid == "zzz"
        #提示调用压缩
        return false
      else
        fresh_infilence_area.each do |fresh_node_uid|
          fresh = self.class.find(fresh_node_uid)
          fresh.change_infilence_node(fresh_parent_node_rid, "move_down")
        end
      end
      update(rid: new_rid)

      children_nodes.each do |child_uid|
        child_node = self.class.find(child_uid)
        child_node.change_children_node(old_rid, new_rid)
      end
      parent_node.update(is_entity: false) if parent_node && parent_node.is_entity
      old_parent_node.update(is_entity: true) if old_parent_node && old_parent_node.children.blank?
    end
    return true
 
  end


  #移动影响范围的节点
  # [参数]
  # 原父级的rid，移动类型 => [move_up, move_down]
  # 需要更改部分的bank_rid进行移动
  def change_infilence_node(old_parent_node_rid, move_type)
    if old_parent_node_rid.present?
      old_pid_parent = rid.slice(0,old_parent_node_rid.size)
      old_bank_id = rid.slice(old_parent_node_rid.size, Common::SwtkConstants::CkpStep)
      children_bank_id = rid.slice((old_parent_node_rid.size + Common::SwtkConstants::CkpStep)..-1)
    else
      old_pid_parent = ""
      old_bank_id = rid.slice(0, Common::SwtkConstants::CkpStep)
      children_bank_id = rid.slice((Common::SwtkConstants::CkpStep)..-1)
    end
    new_bank_id_old_node = ''
    new_self_bank_rid = BankRid.move_bank_rid(old_bank_id, move_type)
    new_bank_id_old_node = old_pid_parent + new_self_bank_rid 
    new_bank_id_old_node = new_bank_id_old_node + children_bank_id unless children_bank_id.blank?
    update(rid: new_bank_id_old_node)
  end

  # 更新子节点信息
  # [参数]
  # 原父rid，新父rid
  # 截取除原父节点的rid, 替换为新的
  def change_children_node(old_rid, new_rid)
    children_bank_id = rid.slice((old_rid.size)..-1)
    new_node_rid = new_rid + children_bank_id
    update(rid: new_node_rid)
  end

  def children
    get_nodes(rid.size, rid, subject, dimesion, category, checkpoint_system_rid).not_equal_rid(rid)
  end

  # def parents
  #   get_nodes(Common::SwtkConstants::CkpStep, parent_node_rid, subject, dimesion, category).not_equal_rid(rid)
  # end

  def parent
    get_nodes(parent_node_rid.size, parent_node_rid, subject, dimesion, category, checkpoint_system_rid).find_by(rid: parent_node_rid)
  end

  def parent_node_rid
    rid.slice(0, rid.size - Common::SwtkConstants::CkpStep)
  end

  #自己的bank_id
  def bank_node_rid
    rid.slice(rid.size - Common::SwtkConstants::CkpStep, Common::SwtkConstants::CkpStep)
  end

  #同级下一个节点
  def get_next_node
    if parent
      nodes = parent.children
    else
      nodes = self.class.where(subject: subject, category: category, dimesion: dimesion, checkpoint_system_rid: checkpoint_system_rid)
      nodes = self.class.where(subject: subject, category: category, dimesion: dimesion, checkpoint_system_id: checkpoint_system_id)
    end
    nodes.where('LENGTH(rid) = ? and SUBSTRING(rid, ?) > ?', rid.size, 0 - Common::SwtkConstants::CkpStep, bank_node_rid).order("rid ASC").first
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
      high_level: high_level,
      checkpoint_system_rid: checkpoint_system_rid,
      chkDisabled: false
    }
  end

  # 获取所属指标体系全部指标包括自己
  #
  def families
    ( subject.nil? || category.nil? || checkpoint_system_rid.nil?)? [] : self.class.where(subject: subject, category: category, checkpoint_system_rid: checkpoint_system_rid)
  end

  private

    def get_nodes(length, rid, subject, dimesion, category, system_rid="000")
      self.class.where('subject = ? and dimesion = ? and category = ? and checkpoint_system_rid = ? and left(rid, ?) = ?', subject, dimesion, category, system_rid, length, rid)
    end 

    def delete_children
      children_nodes = children
      parent_node = parent
      parent_node.update(is_entity: true) if parent_node && parent_node.children.blank?

      return false if children_nodes.blank?
      children.destroy_all
    end

    def set_subject
      self.subject = self.subject || "all"
    end

    def set_xue_duan
      self.category = self.category || "all"
    end

    def set_dimesion
      self.dimesion = self.dimesion || "other"
    end
end
