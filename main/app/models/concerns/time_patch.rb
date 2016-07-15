module TimePatch
  extend ActiveSupport::Concern

  included do
    before_create :set_create_time_stamp
    before_save :set_update_time_stamp
  end

  private
   
  def set_create_time_stamp
    self.dt_add = Time.now
  end

  def set_update_time_stamp
    self.dt_update = Time.now
  end
end
