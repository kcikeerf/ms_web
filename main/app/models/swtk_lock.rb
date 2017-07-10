# -*- coding: UTF-8 -*-

class SwtkLock < ActiveRecord::Base
  self.primary_key = "uid"
  include InitUid  

  # belongs_to :resource, foreign_key: "resource_id", polymorphic: true
  belongs_to :job_list, foreign_key: "job_uid"

  # 被锁定资源
  def resource
    target_class = self.resource_type.constantize
    target_id = self.resource_type.include?("Mongodb::") ? "id" : target_class.primary_key
    target_class.where({ target_id => self.resource_id }).first
  end

  # 排他锁
  def exclusive_lock?
    self.locked_mode == 1
  end

  # 共享锁
  def share_lock?
    self.locked_mode == 2
  end 
end
