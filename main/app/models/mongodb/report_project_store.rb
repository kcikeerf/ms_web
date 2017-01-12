# -*- coding: UTF-8 -*-

class Mongodb::ReportProjectStore
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongodb::MongodbPatch

  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  #scope :by_pup, ->(pup_uid) { where(pup_uid: pup_uid) }

  field :test_id, type: String
  field :area_uid, type: String
  field :area_rid, type: String
  field :pap_uid, type: String

  field :report_name, type: String
  field :report_json, type: String
  field :report_related_json, type: String

  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  index({_id: 1}, {background: true})
  index({test_id: 1, area_uid: 1, tenant_uid:1, loc_uid: 1, pup_uid: 1}, {background: true})
end
