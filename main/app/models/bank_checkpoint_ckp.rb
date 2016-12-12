# -*- coding: UTF-8 -*-

class BankCheckpointCkp < ActiveRecord::Base
#  include Tenacity
#  include MongoMysqlRelations

  self.primary_key = "uid"

  #concerns
  include TimePatch
  include InitUid

  after_destroy :delete_children

  has_many :bank_ckp_comments, foreign_key: "ban_uid"
  has_many :bank_ckp_cats, foreign_key: "ckp_uid"
  has_many :bank_node_catalogs, through: :bank_ckp_cats
#  has_many :bank_tbc_ckps, foreign_key: "ckp_uid3"
#  has_many :bank_nodestructures, through: :bank_tbc_ckps
  belongs_to :bank_nodestructure, foreign_key: "node_uid"

#  t_has_many :bank_ckp_qzps, class_name: "Mongodb::BankCkpQzp", foreign_key: "ckp_uid"
#  t_has_many :bank_qizpoint_qzps, through: :bank_ckp_qzps, class_name: "Mongodb::BankCkpQzp"#, foreign_key: "qzp_uid"
#  from_mysql_has_many :bank_ckp_qzps, :class => "Mongodb::BankCkpQzp", :foreign_key => "ckp_uid"
#  from_mysql_has_many :bank_qizpoint_qzps, :class => Mongodb::BankQizpointQzp, :through => Mongodb::BankCkpQzp

  accepts_nested_attributes_for :bank_ckp_comments, :bank_ckp_cats, allow_destroy: true

  scope :not_equal_rid, ->(rid) { where.not(rid: rid) }
  scope :by_node_uid, ->(uid) { where(node_uid: uid) }
  scope :is_entity, -> { where(is_entity: true) }
  scope :by_dimesion, ->(str) { where(dimesion: str) }

  DEFAULT_LEVEL = [[1], [2], [3,100]]#{level1: [1], level2: [2], level3: [3,100]}

  ########类方法定义：begin#######
  class << self
    # will change in the future
    # 
    # node_uid: node structure uid
    #
    def get_ckps params={}
      result = {"knowledge" => { "label" => Common::Locale::i18n("dict.knowledge"), "children"=>{}}, 
                "skill"=>{"label"=> Common::Locale::i18n("dict.skill"), "children" => {}}, 
                "ability" => {"label" => Common::Locale::i18n("dict.ability"), "children"=>{}}}
      cond_str = "LENGTH(rid) = ?"
      cond_str += " and node_uid = #{params["node_uid"]}" unless params["node_uid"].blank?
      arr = [self.where(cond_str, 3), self.where(cond_str, 6), self.where(cond_str, 9)]
      arr.each{|level|
        level.each{|item|
          current_item = {
            "uid" => item.uid,
            "rid" => item.rid,
            "dimesion" => item.dimesion,
            "checkpoint" => item.checkpoint,
            "is_entity" => item.is_entity || true
          }
          case item.rid.length
          when 3
            result[item.dimesion]["children"][item.rid] = current_item
            result[item.dimesion]["children"][item.rid]["children"] = {}
          when 6
            result[item.dimesion]["children"][item.rid.slice(0,3)]["is_entity"] = false
            result[item.dimesion]["children"][item.rid.slice(0,3)]["children"][item.rid] = current_item
            result[item.dimesion]["children"][item.rid.slice(0,3)]["children"][item.rid]["children"] = {}
          when 9
            result[item.dimesion]["children"][item.rid.slice(0,3)]["children"][item.rid.slice(0,6)]["is_entity"] = false
            result[item.dimesion]["children"][item.rid.slice(0,3)]["children"][item.rid.slice(0,6)]["children"][item.rid] = current_item
          end 
        }
      }
      return result
    end

    def get_web_ckps(node_uid, level_config=[[1], [2], [3], [4], [5,100]])
      Common::CheckpointCkp.ckp_types_loop {|v| get_ckps_by_dimesion(node_uid, v, level_config) }
    end

    def get_ckps_by_dimesion(node_uid, dimesion, level_config)
      level_config = level_config.clone
      nodes = root_node(dimesion)
      nodes[:children] = []
      return nodes if node_uid.blank? || dimesion.blank?

      all_nodes = by_node_uid(node_uid).where(dimesion: dimesion)     
    
      node_level_first = level_config.first
      first_level_nodes = get_nodes_by_rid_length(all_nodes, node_level_first)
      
      level_config.delete(node_level_first)
      first_level_nodes.each {|node| nodes[:children] << build_nodes(all_nodes, level_config, node) }

      [nodes]
    end

    def build_nodes(nodes, level_config, old_node)
      level_config = level_config.clone
      return_node = old_node.organization_hash
      return_node[:children] = []
      level_config.each do |l|
        # p l
        next if (l.first - 1) * Common::SwtkConstants::CkpStep > old_node.rid.size
        # 读取数据库
        # need_nodes = get_nodes_by_rid_length(nodes, l).where("left(rid, ?) = ?", old_node.rid.size, old_node.rid)
        # need_nodes = need_nodes.is_entity if l == level_config.last
        
        need_nodes = get_nodes_by_rid_length(nodes, l).select {|n| n.rid.match(/^#{old_node.rid}/) }
        need_nodes = need_nodes.select{|n| n.is_entity } if l == level_config.last
        
        return return_node if need_nodes.blank?

        need_nodes.to_a.each do |node|
          level_config.delete(l)
          node_json = build_nodes(nodes, level_config, node)
          return_node[:children] << node_json
        end
        
      end
      return_node
    end

    def get_nodes_by_rid_length(nodes, node_level)
      node_level = node_level.clone
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
    
    # 管理后台读取所有指标
    def get_all_ckps(node_uid, str_pid='')
      Common::CheckpointCkp.ckp_types_loop {|dimesion| get_all_ckps_by_dimesion(node_uid, dimesion, str_pid) }
    end

    # get all nodes include pid
    #  
    # str_pid: parent rid
    # node_uid: node structure uid
    # dimesion
    #
    def get_all_ckps_by_dimesion(node_uid, dimesion, str_pid='')
      result = {pid: str_pid, nodes: []}
      return result if node_uid.blank? || dimesion.blank?
      target_objs = self.where(node_uid: node_uid, dimesion: dimesion)
      ckps = BankRid.get_all_child target_objs, str_pid
      result[:nodes] = constructure_ckps(ckps)
      result[:nodes].unshift(root_node(dimesion))
      return result
    end

    # 
    # str_pid: parent rid
    # node_uid: node structure uid
    #
    def save_ckp params
      node_uid = params[:node_uid]
      return nil if node_uid.blank?

      target_objs = where(node_uid: node_uid)
      new_rid = BankRid.get_new_rid target_objs, params[:str_pid]

      new_ckp = self.new(dimesion: params[:dimesion], 
                    rid: new_rid, 
                    node_uid: node_uid, 
                    checkpoint: params[:checkpoint], 
                    desc: params[:desc],
                    advice: params[:advice],
                    sort: params[:sort],
                    is_entity: true,
                    bank_ckp_cats_attributes: params[:cats].presence || [])                 
      
      rid_len = new_rid.size

      ckp_parent_node = target_objs.where(rid: new_ckp.parent_node_rid).first if rid_len > Common::SwtkConstants::CkpStep

      transaction do
        new_ckp.save!
        ckp_parent_node.update(is_entity: false) if ckp_parent_node
        # BankRid.update_ancestors(target_objs, new_ckp, {is_entity: false})
      end
      return new_ckp.organization_hash
    end

    # 循坏生成指标
    def generate_ckp(node_uid, dimesion, ckp_arr, parent_rid = nil)
      ckp_arr.each do |ckp|
        ckp.symbolize_keys!
        name = ckp[:text]
        new_ckp = save_ckp(node_uid: node_uid, checkpoint: name, dimesion: dimesion, str_pid: parent_rid)
        ckp_children = ckp[:items]
        unless ckp_children.blank?
          generate_ckp(node_uid, dimesion, ckp_children, new_ckp[:rid])
        end
      end
    end

    def root_node(dimesion)
      {rid: '', pid: '', nocheck: true, dimesion: dimesion, name: Common::Locale::i18n('managers.root_node'), open: true}
    end

    # 判断使用何种指标
    def judge_ckp_source params
      result = nil
      target_subject, target_category = get_subject_ckp_params params
      
      subject_ckp = BankSubjectCheckpointCkp.where({
          :subject => target_subject,
          :category => target_category
      }).first
      return BankSubjectCheckpointCkp unless subject_ckp.blank?

      node_ckp = BankCheckpointCkp.where({:node_uid => params[:node_uid]}).first
      return BankCheckpointCkp unless node_ckp.blank?
      return result
    end

    def get_subject_ckp_params params
      target_subject = nil
      target_category = nil

      if params[:subject] && params[:grade]
        target_subject = params[:subject]
        target_category =  Common::Grade.judge_xue_duan(params[:grade])
      elsif params[:pap_uid]
        target_pap = Mongodb::BankPaperPap.find(params[:pap_uid])
        target_subject = target_pap.subject
        target_category =  Common::Grade.judge_xue_duan(target_pap.grade)
      elsif params[:node_uid]
        node = BankNodestructure.where(:uid => params[:node_uid]).first
        target_subject = node.subject if node
        target_category = Common::Grade.judge_xue_duan(node.grade) if node
      end

      return target_subject,target_category
    end

    # 绑定教材，目录，指标
    # data = {
    #   node_uid: xxx,
    #   catalogs: [
    #     {}
    #   ],
    #   checkpoints: [
    #     {}
    #   ]
    # }
    def combine_node_catalogs_subject_checkpoints data
      # 更新目录指标
      catalog_uids = data[:catalogs].blank?? []:data[:catalogs].values.map{|item| item[:uid]}
      target_subject_ckp_uids = data[:checkpoints].blank?? []:data[:checkpoints].values.map{|item| item.values}.flatten.map{|item| item[:uid] if item[:uid]}.compact
      # 若教材和目录任一缺失不做更新
      return false if catalog_uids.blank?
      target_node = BankNodestructure.where(:uid => data[:node_uid]).first
      return false unless target_node

      # 存储更新前状态
      old_catalogs_subject_ckp_uids = []

      begin
        catalog_uids.each{|uid|
          target_catalog = BankNodeCatalog.where(:uid => uid).first
          next unless target_catalog
          # 记忆目录更新前状态
          old_catalogs_subject_ckp_uids.push({
            "#{uid}" => target_catalog.bank_subject_checkpoint_ckp_ids || [],
          })
          logger.debug(target_subject_ckp_uids);
          # 置换目录指标
          target_catalog.replace_subject_checkpoints target_subject_ckp_uids
        }

        # 置换教材指标
        target_node.replace_subject_checkpoints
      rescue Exception => ex
        logger.debug "#{__method__.to_s()}>>>rollback begin."
        logger.debug "#{__method__.to_s()}>>>#{ex.message}"
        logger.debug "#{__method__.to_s()}>>>#{ex.backtrace}"
        # 开始目录回退操作
        old_catalogs_subject_ckp_uids.each{|item|
          catalog_uid =item.keys[0]
          ckp_uids = item.values[0]
          target_catalog = BankNodeCatalog.where(:uid => catalog_uid).first
          next unless target_catalog
          target_catalog.replace_subject_checkpoints ckp_uids
        }
        # 开始教材回退操作
        target_node = BankNodestructure.where(:uid => data[:node_uid]).first
        target_node.replace_subject_checkpoints
        logger.debug "#{__method__.to_s()}>>>rollback completed!"
      end
    end

    # 获取教材／目录的指标
    # node_structure_id: 教材uid
    # node_catalog_id: 目录id
    # [Return]: zTree格式用
    #
    def node_catalog_checkpoints params
      #return [] if params[:node_structure_id].blank?# || params[:node_catalog_id].blank?
      result = {}
      dimesion_arr = [:knowledge, :skill, :ability]
      dimesion_arr.each{|dim|
        result[dim]={:nodes=>[]}
        result[dim][:nodes].push(BankSubjectCheckpointCkp.root_node(dim))
      }
      if params[:node_catalog_id]
        target_catalog = BankNodeCatalog.where(:uid => params[:node_catalog_id]).first
        dimesion_arr.each{|dim|
          result[dim][:nodes] += BankSubjectCheckpointCkp.constructure_ckps(target_catalog.bank_subject_checkpoint_ckps.by_dimesion(dim))
        }
      else
        target_node = BankNodestructure.where(:uid => params[:node_structure_id]).first
        dimesion_arr.each{|dim|
          result[dim][:nodes] += BankSubjectCheckpointCkp.constructure_ckps(target_node.bank_subject_checkpoint_ckps.by_dimesion(dim))
        }
      end
      return result
    end

    # 获取指定目录的指标
    # node_catalog_ids: 目录的ids
    #
    def catalogs_checkpoints params
      result = {:knowledge => [], :skill => [], :ability => []}
      ckp_uids = []
      if params[:node_catalog_ids]
        target_catalogs =  BankNodeCatalog.where(:uid => params[:node_catalog_ids])
        target_catalogs.each{|target_catalog|
          target_catalog.bank_subject_checkpoint_ckps.each{|ckp|
            result[ckp.dimesion.to_sym].push(
              ckp.organization_hash
            ) unless ckp_uids.include?(ckp.uid)
            ckp_uids.push(ckp.uid)
          }
        }
      end
      return result
    end
  end
  ########类方法定义：end#######

  #
  # str_uid: current check point uid 
  # str_pid: parent rid
  # node_uid: node structure uid
  #
  #
  def update_ckp params
    bank_ckp_cats.destroy_all
    ckp_hash = params.extract!(:checkpoint, :desc, :advice, :sort)
    ckp_hash[:bank_ckp_cats_attributes] = params[:cats].presence || []
    update(ckp_hash)
    
    return organization_hash
  end

  def move_node(move_to_parent_uid)
    nodes = self.class.where(node_uid: node_uid)
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


  def bank_qizpoint_qzps
    result_arr =[]
    qzps = Mongodb::BankCkpQzp.where(ckp_uid: self.uid).to_a
    qzps.each{|qzp|
      result_arr << Mongodb::BankQizpointQzp.where(_id: qzp.qzp_uid).first
    }
    return result_arr
  end

  def children
    get_nodes(rid.size, rid, node_uid, dimesion).not_equal_rid(rid)
  end

  def parents
    get_nodes(Common::SwtkConstants::CkpStep, parent_node_rid, node_uid, dimesion).not_equal_rid(rid)
  end

  def parent
    get_nodes(parent_node_rid.size, parent_node_rid, node_uid, dimesion).find_by(rid: parent_node_rid)
  end

  def parent_node_rid
    rid.slice(0, rid.size - Common::SwtkConstants::CkpStep)
  end

  def organization_hash
    { 
      id: uid, 
      uid: uid,
      rid: rid,
      pid: rid.slice(0, ((rid.size - 3 < 0) ? 0 :(rid.size - 3))),
      dimesion: dimesion,
      checkpoint: checkpoint,
      name: checkpoint,
      is_entity: is_entity,
      advice: advice,
      desc: desc,
      sort: sort,
      ckp_source: Common::CheckpointCkp::CkpSource::Default,
      nocheck: is_entity^1
    }
  end

  # 获取所属指标体系全部指标包括自己
  #
  def families
    node_uid.nil?? [] : self.class.where(node_uid: node_uid)
  end
  
  # 指标所属学科
  # *教材指标属性不包含学科，通过教材获取学科信息
  #
  def subject
    bank_nodestructure.nil?? nil : bank_nodestructure.subject
  end

  private

  def get_nodes(length, rid, node_uid, dimesion)
    self.class.where('node_uid = ? and dimesion = ? and left(rid, ?) = ?', node_uid, dimesion, length, rid)
  end 

  def delete_children
    children_nodes = children
    parent_node = parent
    parent_node.update(is_entity: true) if parent_node && parent_node.children.blank?

    return false if children_nodes.blank?
    children.destroy_all
  end

  def self.constructure_ckps ckps
    # ckps.map{|item| item.organization_hash }
    ckps.map(&:organization_hash)
  end

end
