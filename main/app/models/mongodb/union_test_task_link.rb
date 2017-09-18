# -*- coding: UTF-8 -*-
#

class Mongodb::UnionTestTaskLink
  include Mongoid::Document
  include Mongodb::MongodbPatch

  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  belongs_to :union_test, class_name: "Mongodb::UnionTest"

  field :task_uid, type: String
  
  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  index({union_test_id: 1, task_uid: 1}, {unique: true, background: true})

  def task
    TaskList.where(uid: self.task_uid).first
  end
end
