# -*- coding: UTF-8 -*-

class Mongodb::BankQuizOption
  include Mongoid::Document
  include Mongodb::MongodbPatch
  include SwtkLockPatch

  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  belongs_to :bank_quiz_qiz, class_name: "Mongodb::BankQuizQiz"

  field :content, type: String
  field :is_answer, type: Boolean, default: false
  field :dt_add, type: DateTime
  field :dt_update, type: DateTime



  def save_quiz_option params
    begin
      self.content = params["optionContent"] || ""
      self.is_answer = params["isAnswer"] || false
      self.save!
    rescue Exception => ex
      p ex.message
    return false
    end
   return true 
  end

end