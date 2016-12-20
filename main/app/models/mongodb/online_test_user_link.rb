class Mongodb::OnlineTestUserLink
  include Mongoid::Document
  include Mongodb::MongodbPatch
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  field :online_test_id, type: String 
  field :user_id, type: String
  field :wx_user_id, type: String
  field :online_test_status, type: String
  field :task_uid, type: String

  field :dt_add, type: DateTime
  field :dt_update, type: DateTime
end
