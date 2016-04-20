module ActiveRecordPatch
#  def self.included(base)
#    base.extend ClassMethods
#  end

#  module ClassMethods
    private
    def set_create_time_stamp
      self.dt_add = DateTime.now
    end

    def set_update_time_stamp
      self.dt_update = DateTime.now
    end
#  end
end
