# -*- coding: UTF-8 -*-

module Mongodb::MongodbPatch
  private
  def set_create_time_stamp
    self.dt_add = DateTime.now.to_s
  end

  def set_update_time_stamp
    self.dt_update = DateTime.now.to_s
  end
end