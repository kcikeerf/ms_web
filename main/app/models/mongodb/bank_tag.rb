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

  def paper_tag_links
    PaperTagLink.where(tag_id: self._id.to_s)
  end

  def bank_paper_pap_ids
    paper_tag_links.map(&:paper_id)
  end

  def bank_paper_paps
    Mongodb::BankPaperPap.where({id: {"$in" => bank_paper_pap_ids}})
  end

end
