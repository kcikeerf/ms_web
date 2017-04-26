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

  #获取大纲节点的祖先rid
  # [参数]
  #    空
  # [返回值]
  #    祖先节点的rid数组
  #
  def ancestor_rids
    result = []
    rids_arr = rid.scan(/.{3}/)
    rids_size = rids_arr.size
    (rids_size - 1).times.each{|index|
      result << rids_arr[0..index].join("")
    }
    return result 
  end

  #获取大纲节点的祖先
  # [参数]
  #    空
  # [返回值]
  #    祖先节点的数组
  #
  def ancestors
    ancestor_rids.map{|rid|
      self.class.where(bank_paper_pap_id: self.bank_paper_pap_id, rid: rid).first
    }
  end
end
