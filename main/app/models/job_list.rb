class JobList < ActiveRecord::Base
  self.primary_key = "uid"

  include ActiveRecordPatch
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  before_create :init_uid

  belongs_to :task_list, foreign_key: "task_uid"
  has_many :swtk_locks, foreign_key: "job_uid"

  private

  def init_uid
    self.uid=Time.now.to_snowflake.to_s
  end
end
