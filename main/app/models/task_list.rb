class TaskList < ActiveRecord::Base
  self.primary_key = "uid"

  include ActiveRecordPatch
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  before_create :init_uid

  belongs_to :user, foreign_key: "user_id"
  has_many :job_lists, foreign_key: "task_uid"

  scope :by_task_status, ->(str) { where(status: str) }
  scope :by_task_type, ->(str) { where(task_type: str) }

  private

  def init_uid
    self.uid=Time.now.to_snowflake.to_s
  end
end
