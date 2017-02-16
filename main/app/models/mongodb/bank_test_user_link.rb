class Mongodb::BankTestUserLink
  include Mongoid::Document

  belongs_to :bank_test, class_name: "Mongodb::BankTest"

  field :user_id, type: String

  index({bank_test_id: 1, user_id: 1}, {unique: true, background: true})

  def user
    User.where(id: self.user_id).first
  end
end
