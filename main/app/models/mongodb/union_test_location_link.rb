# -*- coding: UTF-8 -*-
#

class Mongodb::UnionTestLocationLink
  include Mongoid::Document

  belongs_to :union_test, class_name: "Mongodb::UnionTest"

  field :loc_uid, type: String

  index({union_test_id: 1, loc_uid: 1}, {unique: true, background: true})

  def location
    Location.where(uid: self.loc_uid).first
  end
end
