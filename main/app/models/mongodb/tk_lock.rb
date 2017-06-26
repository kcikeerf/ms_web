# -*- coding: UTF-8 -*-

class Mongodb::TkLock
  include Mongoid::Document
  include Mongodb::MongodbPatch

  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  embedded_in :bank_paper_pap, class_name: "Mongodb::BankPaperPap"
  embedded_in :bank_quiz_qiz, class_name: "Mongodb::BankQuizQiz"
  embedded_in :bank_qizpoint_qzp, class_name: "Mongodb::BankQizpointQzp"

  field :rw, type: Integer
  field :locked_by, type: String
  # field :expired_at, type: DateTime

  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  def read_lock?
    self.rw == 1
  end

  def write_lock?
    self.rw == 2
  end  

  def rw_lock?
    self.rw = 3
  end

  #######私有方法#######
  private

end
