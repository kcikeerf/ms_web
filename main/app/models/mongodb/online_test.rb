class Mongodb::OnlineTest
  include Mongoid::Document
  include Mongodb::MongodbPatch
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  field :pap_uid, type: String
  field :user_id, type: String
  field :wx_openid, type: String
  field :result_json, type: String

  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

end
