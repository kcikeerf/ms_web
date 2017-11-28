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
  # 微信在线测试，公开测试的时候，使用用户的token
  field :user_token, type: String

  # wx在线测试，检讨中
  field :online_test_id, type: String
  field :wx_user_id, type: String
  ###

  field :rc_test_user_house_id
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

  class << self
    def save_all_qzp qzps, rc_user_id
      qzps.each do |params|
        test_score = self.new
        params = params.merge({:rc_test_user_house_id => rc_user_id})
        test_score.save_ins(params.to_hash.deep_symbolize_keys)
      end      
    end
  end

  def save_ins params
    self.pap_uid = params[:pap_uid] if params[:pap_uid].present?
    self.qzp_uid = params[:qzp_uid] if params[:qzp_uid].present?
    self.order = params[:order] if params[:order].present?
    self.real_score = params[:real_score] if params[:real_score].present?
    self.full_score = params[:full_score] if params[:full_score].present?
    self.rc_test_user_house_id = params[:rc_test_user_house_id] if params[:rc_test_user_house_id].present?
    self.save!
  end
end

