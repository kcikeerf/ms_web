# -*- coding: UTF-8 -*-

class Mongodb::ClassReport
  include Mongoid::Document
  include Mongodb::MongodbPatch

  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  field :loc_uid, type: String
  #
  field :province, type: String
  field :city, type: String
  field :district, type: String
  field :school, type: String
  field :grade, type: String
  field :classroom, type: String
  #
  field :pap_uid, type: String
  field :report_name, type: String
  field :report_json, type: String
   
  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  index({_id: 1}, {background: true})
end
