# -*- coding: UTF-8 -*-

class Mongodb::BankCkpQzp
  include Mongoid::Document
  validates :ckp_uid, :qzp_uid, length: {maximum: 36}

  field :ckp_uid, type: String
  field :qzp_uid, type: String
  #标示来源
  field :source_type, type: String
#  field :weights, type: Float

  def save_ckp_qzp qzpUid=nil, ckpUid=nil, sourceType=nil
    ckp_uid = ckpUid.nil?? nil:ckpUid
    qzp_uid = qzpUid.nil?? nil:qzpUid
    source_type = sourceType.nil?? nil:sourceType
    save!
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
