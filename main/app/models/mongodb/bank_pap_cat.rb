# -*- coding: UTF-8 -*-

class Mongodb::BankPapCat
  include Mongoid::Document
  include Mongodb::MongodbPatch
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

#  validates :pap_uid, :cat_uid, length: {maximum: 36}

  belongs_to :bank_paper_pap, class_name: "Mongodb::BankPaperPap"

  field :pap_uid, type: String
  field :cat_uid, type: String

  field :dt_add, type: DateTime
  field :dt_update, type: DateTime
end
