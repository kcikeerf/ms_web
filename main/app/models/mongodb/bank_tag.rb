# -*- coding: UTF-8 -*-

class Mongodb::BankTag
  include Mongoid::Document
  include Mongodb::MongodbPatch

  before_create :set_create_time_stamp
  before_save :set_update_time_stamp
  has_many :bank_quiz_tag_links, class_name: "Mongodb::BankQuizTagLink", foreign_key: "tag_uid"

  field :content, type: String
  # field :qoq_id, type: String

  # field :qzp_uid, type: String
  field :dt_add, type: DateTime
  field :dt_update, type: DateTime  

  def bank_qzp_ids
    bank_quiz_tag_links.map(&:qzp_uid)
  end

  def bank_qizpoint_qzps
    Mongodb::BankQizpointQzp.where({id: {"$in" => bank_qzp_ids}})
  end

  def bank_quiz_ids
    bank_quiz_tag_links.map(&:quiz_uid)
  end

  def bank_quiz_qizs
    Mongodb::BankQuizQiz.where({id: {"$in" => bank_quiz_ids}})
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
