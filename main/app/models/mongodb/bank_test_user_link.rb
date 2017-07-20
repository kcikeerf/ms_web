class Mongodb::BankTestUserLink
  include Mongoid::Document
  include Mongodb::MongodbPatch
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  belongs_to :bank_test, class_name: "Mongodb::BankTest"

  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :lt_times, ->(num) { where(test_times: {"$lt" => num }) }
  scope :gt_times, ->(num) { where(test_times: {"$gt" => num }) }
  scope :lte_times, ->(num) { where(test_times: {"$lte" => num }) }
  scope :gte_times, ->(num) { where(test_times: {"$gte" => num }) }

  field :user_id, type: String
  field :test_date, type: DateTime
  field :test_duration, type: Integer # 测试持续时间
  field :test_times, type: Integer, default: 0 # 测试次数
  field :test_status, type: String, default: nil 
  field :task_uid, type: String
  
  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  index({bank_test_id: 1, user_id: 1}, {unique: true, background: true})

  def user
    User.where(id: self.user_id).first
  end
end
