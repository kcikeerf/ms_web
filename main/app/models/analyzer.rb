class Analyzer < ActiveRecord::Base
  self.primary_key = "uid"

  #concerns
  include TimePatch
  include InitUid

  belongs_to :user
  has_many :score_uploads, foreign_key: "ana_uid"
  has_one :active_create_report_task, ->{ where(type: Task::Type::CreateReport , status: Task::Status::Active)},
          class_name: "TaskList", 
          foreign_key: "ana_uid"
          
  has_one :active_upload_score_task, ->{ where(type: Task::Type::UploadScore , status: Task::Status::Active)},
          class_name: "TaskList", 
          foreign_key: "ana_uid"

          

end
