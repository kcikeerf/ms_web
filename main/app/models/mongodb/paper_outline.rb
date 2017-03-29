# -*- coding: UTF-8 -*-

class Mongodb::PaperOutline
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :bank_paper_pap, class_name: "Mongodb::BankPaperPap"
  has_many :bank_quiz_qizs, class_name: "Mongodb::BankQuizQiz"
  has_many :bank_qizpoint_qzps, class_name: "Mongodb::BankQizpointQzp"

  field :name, type: String
  field :rid, type: String
  field :order, type: String
  field :level, type: String
  field :is_end_point, type: String

  def ancestor_rids
    result = []
    rids_arr = rid.scan(/.{3}/)
    rids_size = rids_arr.size
    (rids_size - 1).times.each{|index|
      result << rids_arr[0..index].join("")
    }
    return result 
  end
end
