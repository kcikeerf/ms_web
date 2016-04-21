module Mongodb::MongodbPatch
  private
  def set_create_time_stamp
    self.dt_add = DateTime.now
  end

  def set_update_time_stamp
    self.dt_update = DateTime.now
  end
end
  
