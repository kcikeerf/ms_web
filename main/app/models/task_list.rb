class TaskList < ActiveRecord::Base
  self.primary_key = "uid"

  include ActiveRecordPatch
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  before_create :init_uid

  belongs_to :analyzer, foreign_key: "ana_uid"
  has_many :job_lists, foreign_key: "task_uid"

  private

  def init_uid
    self.uid=Time.now.to_snowflake.to_s
  end
end
