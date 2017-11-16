# -*- coding: UTF-8 -*-

class Mongodb::BankTeaPap
  include Mongoid::Document

  validates :tea_uid, :pap_uid, length: {maximum: 36}
  belongs_to :bank_paper_pap, class_name: "Mongodb::BankPaperPap", foreign_key: "pap_uid"

  field :tea_uid, type: String
  field :pap_uid, type: String

  index({tea_uid: 1}, {background: true})
  index({pap_uid: 1}, {background: true})

  def save_tea_pap tea_uid=nil, pap_uid=nil
      self.tea_uid = tea_uid.nil?? nil:tea_uid
      self.pap_uid = pap_uid.nil?? nil:pap_uid
      self.save!
    return true
  end

  def teacher
    Teacher.where(uid: tea_uid).first
  end
  
  def destroy_tea_pap
    logger.info("=======Destroy Teacher And Paper Relation========")
    begin
      self.destroy!
    rescue Exception=>ex
      logger.debug ex.message
      logger.debug ex.backtrace
      return false
    end
    return true
  end
end
