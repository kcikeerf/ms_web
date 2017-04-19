module TkLockPatch
  extend ActiveSupport::Concern

  included do
    def lock! _mode, _user_id
      p _mode.to_s
      self.tk_lock = Mongodb::TkLock.new(rw: _mode, locked_by: _user_id )
      self.save!
    end

    def unlock!
      return true unless self.tk_lock
      self.tk_lock.destroy!
    end
  end
end
