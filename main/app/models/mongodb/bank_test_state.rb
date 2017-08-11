class Mongodb::BankTestState
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongodb::MongodbPatch

  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  field :area_rid, type: String 
  field :total_num, type: Integer  
  field :project_num, type: Integer
  field :grade_num, type: Integer 
  field :klass_num, type: Integer 
  field :pupil_num, type: Integer   

  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  belongs_to :bank_test, class_name:"Mongodb::BankTest" 
end