# -*- coding: UTF-8 -*-

class Mongodb::BankQuizTagLink
  include Mongoid::Document
  include Mongodb::MongodbPatch

  before_create :set_create_time_stamp
  before_save :set_update_time_stamp
  belongs_to :bank_tag, class_name: "Mongodb::BankTag", foreign_key: "tag_uid"
  belongs_to :bank_quiz_qiz, class_name: "Mongodb::BankQuizQiz", foreign_key: "quiz_uid"
  belongs_to :bank_qizpoint_qzp, class_name: "Mongodb::BankQizpointQzp", foreign_key: "qzp_uid"



  # validates :tag_uid, :qoq_uid, length: {maximum: 36}

  field :tag_uid, type: String
  field :qzp_uid, type: String
  field :quiz_uid, type: String

  # field :qzp_uid, type: String
  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  index({tag_uid: 1}, {background: true})
  
  def save_ins quizUid=nil, qzpUid=nil, tagUid=nil
    self.tag_uid = tagUid.nil?? nil : tagUid
    self.quiz_uid = quizUid.nil?? nil : quizUid
    self.qzp_uid = qzpUid.nil?? nil : qzpUid
    self.save!
  end

  # def bank_qizpoint_qzp
  #   Mongodb::BankQizpointQzp.where(_id: self.quiz_id).first
  # end

  # def bank_quiz_qiz
  #   Mongodb::BankQuizQiz.where(_id: self.qzp_id).first
  # end

  # def bank_tag
  #   Mongodb::BankTag.where(_id: self.tag_uid).first
  # end

  def destroy_ckp_qzp
    begin
      self.destroy!
    rescue Exception=>ex
      return false
    end
    return true
  end

end
