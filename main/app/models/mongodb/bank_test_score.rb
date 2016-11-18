# -*- coding: UTF-8 -*-

class Mongodb::BankTestScore
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  include Mongodb::MongodbPatch

  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  before_save :format_float

  #地理位置
  field :area_uid, type: String
  field :area_rid, type: String
  #Tenant
  field :tenant_uid, type: String
  #班级信息
  field :loc_uid, type: String
  #测试
  field :test_id, type: String
  #学生
  field :pup_uid, type: String
  #试卷关联细心
  field :pap_uid, type: String
  field :qzp_uid, type: String
  field :order, type: String
  field :real_score, type: Float
  field :full_score, type: Float

  field :dt_add, type: DateTime
  field :dt_update, type: DateTime
  
  #索引
  index({_id: 1}, {background: true})
  index({dt_update:-1},{background: true})
  index({test_id: 1, pup_uid: 1}, {background: true})  

  private
  def format_float
    self.real_score = self.real_score.nil?? 0.0:("%.2f" % self.real_score).to_f
  end
end

