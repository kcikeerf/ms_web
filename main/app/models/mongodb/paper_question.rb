class Mongodb::PaperQuestion
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  has_many :bank_tests, class_name: "Mongodb::BankTest"

  field :name, type: String
  field :heading, type: String
  field :subheading, type: String
  field :quiz_type, type: String
  field :quiz_date, type: DateTime
  field :quiz_time, type: Integer
  field :full_score, type: Float
  field :area_uid, type: String
  field :area_rid, type: String
  field :tenant_uid, type: String

end
