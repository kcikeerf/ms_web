# -*- coding: UTF-8 -*-
#

class Mongodb::BankTestAreaLink
  include Mongoid::Document

  belongs_to :bank_test, class_name: "Mongodb::BankTest"

  field :area_uid, type: String

  index({bank_test_id: 1, area_uid: 1}, {unique: true, background: true})

  def area
    Area.where(uid: self.area_uid).first
  end
end
