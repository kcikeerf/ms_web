# -*- coding: UTF-8 -*-

class BankRid < ActiveRecord::Base

  class << self
    # get <obj> model <pid> rid chindren nodes
    #
    # obj: model name
    # pid: parent node rid
    #
    def get_child obj=nil,pid
      result = []
      return result if obj.blank?
      pid_len = pid.size
      pid="" if pid.blank?
      return result if pid_len == Common::SwtkConstants::CkpDepth * Common::SwtkConstants::CkpStep
      target_len = pid_len + Common::SwtkConstants::CkpStep
      cond_str = "LENGTH(rid) > ? and LENGTH(rid) <= ? and SUBSTR(rid, 1, ?) = ?" 
      result = obj.where(cond_str, pid_len, target_len, pid_len, pid).to_a
      return result
    end

    def get_all_child obj=nil,pid
      result = []
      return result if obj.blank?
      pid="" if pid.blank?
      pid_len = pid.size
      return result if pid_len == Common::SwtkConstants::CkpDepth * Common::SwtkConstants::CkpStep
      cond_str = "SUBSTR(rid, 1, ?) = ?"
      result = obj.where(cond_str, pid_len, pid).to_a
      return result
    end

    def get_all_higher_nodes obj=nil,target
      result = [] 
      return result if obj.blank?
      rid_len = target.nil??  0 : target.rid.size 
      return result if rid_len == Common::SwtkConstants::CkpStep
      
      cond_arr = []
      [*1..(rid_len/Common::SwtkConstants::CkpStep - 1)].each{|index|
        cond_arr << "(rid=SUBSTR('#{target.rid}', 1, #{Common::SwtkConstants::CkpStep* index}) and LENGTH(rid)=#{Common::SwtkConstants::CkpStep* index})" 
      }

      cond_str = cond_arr.join(" or ")
      result = obj.where(cond_str).to_a
      return result
    end

    def update_ancestors obj, current, attrs
      return false if (obj.blank? || current.blank? || attrs.blank?)

      rid_len = current.rid.size
      [*1..(rid_len/Common::SwtkConstants::CkpStep - 1)].each{|index|
        cond_str = "rid = ?"
        ancestors = obj.where(cond_str, current.rid.slice(0, Common::SwtkConstants::CkpStep*index))
        ancestors.each{|ancestor|
          ancestor.update_attributes(attrs)
        }
      } 
          
    end

    # def move_catalog former_rid, later_rid

    # end

    # get new node rid
    #
    # obj: model name
    # pid: parent node rid
    #
    def get_new_rid obj, pid, from_child_rid=nil
      result = ""
      #return result if obj.blank?
      pid = pid || ""
      pid_len = pid.size
      return result if pid_len == Common::SwtkConstants::CkpDepth * Common::SwtkConstants::CkpStep
      target_len = pid_len + Common::SwtkConstants::CkpStep
      cond_str = "LENGTH(rid) > ? and LENGTH(rid) <= ? and SUBSTR(rid, 1, ?) = ?"
  #    max_child_rid = obj.where(cond_str, pid_len, target_len, pid_len, pid).maximum('rid')
  #    if max_child_rid
      child_rids = obj.nil?? []:obj.where(cond_str, pid_len, target_len, pid_len, pid).map{|item| item.rid.slice(pid_len, Common::SwtkConstants::CkpStep)}
      child_rids = child_rids.blank?? [""] : child_rids 
      #unless child_rids.blank?
        #next_rid = self.where("rid > ?", max_child_rid.slice(pid_len, Common::SwtkConstants::CkpStep)).limit(1)
      p ">>>>#{child_rids}"
      rid_exclude_range_cond_str = "rid not in (?)"
      if from_child_rid
        rid_exclude_range_cond_str += " and rid > '{from_child_rid}'"
      end

      next_rid = where(rid_exclude_range_cond_str, child_rids).limit(1)
      result = next_rid.blank?? "" : (pid+next_rid[0].rid)
      #else
      #  result = pid + first.rid
      #end
      return result
    end

    # 根据父级rid获取新的bank_rid
    # [参数]
    # obj => 满足学科学段三维的所有节点, pid => 父级的rid
    # [返回值]
    # 当有子节点的bank_id等于zzz时 返回 "", 否则返回新的rid
    def get_new_bank_rid obj, pid
      result = ""
      pid = pid || ""
      pid_len = pid.size
      return result if pid_len == Common::SwtkConstants::CkpDepth * Common::SwtkConstants::CkpStep
      target_len = pid_len + Common::SwtkConstants::CkpStep

      cond_str = "LENGTH(rid) > ? and LENGTH(rid) <= ? and SUBSTR(rid, 1, ?) = ? "

      last_child_rid = obj.blank? ? [] : obj.where(cond_str, pid_len, target_len, pid_len, pid).order("rid DESC").limit(1).map{|item| item.rid.slice(pid_len, Common::SwtkConstants::CkpStep)}
      next_bank_rid = "" 
      if last_child_rid.blank? 
        next_bank_rid = "000" 
      else
        if last_child_rid[0] == "zzz"
          return result
          #进行压缩
        else
          next_bank_rid =(last_child_rid[0].to_i(36) + 1).to_s(36).rjust(3, '0')          
        end
      end
      result = pid + next_bank_rid
      return result    
    end

    # 移动bank_rid 
    # [参数]
    # old_bank_id => 原bank_rid, 移动类型  => [向前或向后移动]
    # [返回值]
    # 新bank_rid
    def move_bank_rid(old_bank_id, move_type)
      case move_type
      when "move_up"
        if old_bank_id != "000"
          new_bank_rid = (old_bank_id.to_i(36) - 1).to_s(36).rjust(3, '0')
        end
      when "move_down"
        if old_bank_id != "zzz"
          new_bank_rid = (old_bank_id.to_i(36) + 1).to_s(36).rjust(3, '0')
        end
      end
      return new_bank_rid
    end

    # 获取某一范围内的rid的紧邻arid的rid
    def get_next_rid obj=nil, arid, brid
      arid = arid || ""
      brid = brid || ""
      
      cmp_result = Common::CheckpointCkp::compare_rid_plus(arid, brid)
      arid_parent = arid.slice(0, arid.length - Common::SwtkConstants::CkpStep)
      if (cmp_result == 1)
        arid, brid = brid, arid
      elsif (cmp_result == 0)
        arid_parent = arid
        arid = nil
      end
      get_new_rid obj, arid_parent, arid
    end

  end
end
