class BankRid < ActiveRecord::Base

  # get <obj> model <pid> rid chindren nodes
  #
  # obj: model name
  # pid: parent node rid
  #
  def self.get_child obj=nil,pid
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

  def self.get_all_child obj=nil,pid
    result = []
    return result if obj.blank?
    pid="" if pid.blank?
    pid_len = pid.size
    return result if pid_len == Common::SwtkConstants::CkpDepth * Common::SwtkConstants::CkpStep
    cond_str = "SUBSTR(rid, 1, ?) = ?"
    result = obj.where(cond_str, pid_len, pid).to_a
    return result
  end

  # get new node rid
  #
  # obj: model name
  # pid: parent node rid
  #
  def self.get_new_rid obj=nil,pid
    result =""
    return result if obj.blank?
    pid="" if pid.blank?
    pid_len = pid.size
    return result if pid_len == Common::SwtkConstants::CkpDepth * Common::SwtkConstants::CkpStep
    target_len = pid_len + Common::SwtkConstants::CkpStep
    cond_str = "LENGTH(rid) > ? and LENGTH(rid) <= ? and SUBSTR(rid, 1, ?) = ?"
#    max_child_rid = obj.where(cond_str, pid_len, target_len, pid_len, pid).maximum('rid')
#    if max_child_rid
    child_rids = obj.where(cond_str, pid_len, target_len, pid_len, pid).map{|item| item.rid.slice(pid_len, Common::SwtkConstants::CkpStep)}
    unless child_rids.blank?
      #next_rid = self.where("rid > ?", max_child_rid.slice(pid_len, Common::SwtkConstants::CkpStep)).limit(1)
      next_rid = self.where("rid not in (?)", child_rids).limit(1)
      result = next_rid.nil?? pid:(pid+next_rid[0].rid)
    else
      result = pid + self.first.rid
    end
    return result
  end

end
