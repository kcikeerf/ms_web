class TestUserLink < ActiveRecord::Base
  belongs_to :user ,:class_name=>"User", :foreign_key=>"user_id"

  def bank_test
    Mongodb::BankTest.where(_id: self.bank_test_id).first
  end
end
