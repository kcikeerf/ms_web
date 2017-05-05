# -*- coding: UTF-8 -*-

class Mongodb::BankTestScore
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongodb::MongodbPatch

  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  ### 
  # 正常测试
  field :area_uid, type: String
  field :area_rid, type: String
  field :tenant_uid, type: String
  field :loc_uid, type: String
  field :test_id, type: String
  field :pup_uid, type: String
  # 非项目用户的token
  field :tk_token, type: String

  ### 
  # wx在线测试
  field :online_test_id, type: String
  field :wx_user_id, type: String
  ###

  field :pap_uid, type: String
  field :qzp_uid, type: String
  field :order, type: String
  field :real_score, type: Float
  field :full_score, type: Float

  field :dt_add, type: DateTime
  field :dt_update, type: DateTime
  
  index({_id: 1}, {background: true})
  index({dt_update:-1},{background: true})
  index({test_id: 1, pup_uid: 1}, {background: true})

end

