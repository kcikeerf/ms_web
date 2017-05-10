class Mongodb::BankTestUserLink
  include Mongoid::Document
  include Mongodb::MongodbPatch
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  belongs_to :bank_test, class_name: "Mongodb::BankTest"

  field :user_id, type: String
  
  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  index({bank_test_id: 1, user_id: 1}, {unique: true, background: true})

  def user
    User.where(id: self.user_id).first
  end
end
