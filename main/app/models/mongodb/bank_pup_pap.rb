# -*- coding: UTF-8 -*-

class Mongodb::BankPupPap
  include Mongoid::Document

  validates :pup_uid, :pap_uid, length: {maximum: 36}

  field :pup_uid, type: String
  field :pap_uid, type: String

  index({pup_uid: 1}, {background: true})
  index({pap_uid: 1}, {background: true})
  
  def save_pup_pap pup_uid=nil, pap_uid=nil
      self.pup_uid = pup_uid.nil?? nil:pup_uid
      self.pap_uid = pap_uid.nil?? nil:pap_uid
      self.save!
    return true
  end 

  def destroy_pup_pap
    logger.info("=======Destroy Pupil And Paper Relation========")
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
