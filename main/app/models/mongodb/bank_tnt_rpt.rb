class Mongodb::BankTntRpt
  include Mongoid::Document
  include Mongodb::MongodbPatch
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  field :tnt_uid, type: String
  field :rpt_uid, type: String

  field :dt_add, type: DateTime
  field :dt_update, type: DateTime
end
