# -*- coding: UTF-8 -*-

class Mongodb::OnlineTestZhFzqnSuggestion
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongodb::MongodbPatch

  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  field :overall_type, type: String # AAA,BBB, CCC,EEE....
  field :suggestion, type: String

  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

end
