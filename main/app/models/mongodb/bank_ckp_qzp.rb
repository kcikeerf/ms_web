# -*- coding: UTF-8 -*-

class Mongodb::BankCkpQzp
  include Mongoid::Document
  include Mongodb::MongodbPatch

  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  validates :ckp_uid, :qzp_uid, length: {maximum: 36}

  field :ckp_uid, type: String
  field :qzp_uid, type: String
  #标示来源
  field :source_type, type: String
#  field :weights, type: Float
  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  def save_ckp_qzp qzpUid=nil, ckpUid=nil, sourceType=nil
    self.ckp_uid = ckpUid.nil?? nil:ckpUid
    self.qzp_uid = qzpUid.nil?? nil:qzpUid
    self.source_type = sourceType.nil?? nil:sourceType
    self.save!
    return true
  end

  def destroy_ckp_qzp
    begin
      self.destroy!
    rescue Exception=>ex
      return false
    end
    return true
  end

end
