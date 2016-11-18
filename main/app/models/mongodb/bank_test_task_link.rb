# -*- coding: UTF-8 -*-

class Mongodb::BankTestTaskLink
  include Mongoid::Document
  include Mongodb::MongodbPatch
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  belongs_to :bank_test, class_name: "Mongodb::BankTest"

  field :task_uid, type: String
  
  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  def task
  	TaskList.where(uid: task_uid).first
  end
end
