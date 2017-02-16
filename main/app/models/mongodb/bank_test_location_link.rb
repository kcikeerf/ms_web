# -*- coding: UTF-8 -*-
#

class Mongodb::BankTestLocationLink
  include Mongoid::Document

  belongs_to :bank_test, class_name: "Mongodb::BankTest"

  field :loc_uid, type: String

  index({bank_test_id: 1, loc_uid: 1}, {unique: true, background: true})

  def location
    Location.where(uid: self.loc_uid).first
  end
end
