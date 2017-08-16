# -*- coding: UTF-8 -*-

module SwtkLockPatch
  extend ActiveSupport::Concern

  included do
    before_save :check_lock_if_change!
    before_destroy :check_lock_if_change!
    attr_accessor :current_job_uid
    attr_accessor :current_user_id
    #has_one :swtk_lock, class_name: "SwtkLock", foreign_key: "resource_id", as: :resource

    # 获取锁对象
    def swtk_lock
      SwtkLock.where(resource_id: self.id.to_s).order(updated_at: :desc).first
    end

    # 获取排斥锁
    # 非操作用户不得更新
    def acquire_exclusive_lock!
      raise SwtkErrors::CannotLockALockingResource.new("Already locked!") if locked?
      set_exclusive_lock
    end

    # 获取共享锁
    # 所有用户不得更新
    def acquire_share_lock!
      raise SwtkErrors::CannotLockALockingResource.new("Already locked!") if locked?
      set_share_lock
    end

    # 释放锁
    def release_lock!
      return true unless locked?
      if locked_by_current_operator?
        if exclusive_lock?        
          swtk_lock.destroy!
        else
          _locked_times = swtk_lock.locked_times - 1
          if _locked_times >= 1
            _locked_owner = (swtk_lock.locked_owner.split(",") - [@current_user_id]).join(",")
            _job_uid = (swtk_lock.job_uid.split(",") - [@current_job_uid]).join(",")            
            swtk_lock.update({
              locked_times: _locked_times,
              locked_owner: _locked_owner,
              job_uid: _job_uid
            })
          else
            swtk_lock.destroy! 
          end
        end
      else
        raise SwtkErrors::ReleaseResourceLockFailed.new("Not locked by current operator!")
      end
    end

    # 强制清除
    def force_release_lock!
      return true unless locked?
      swtk_lock.destroy! 
    end

    # 是否锁了
    def locked?
      swtk_lock.present?
    end 

    # 排他锁
    def exclusive_lock?
      locked? && swtk_lock.exclusive_lock?
    end

    # 共享锁
    def share_lock?
      locked? && swtk_lock.share_lock?
    end
    
    # 设置原操作对象信息
    def set_operator _user_id, _job_uid
      @current_user_id = _user_id
      @current_job_uid = _job_uid
    end

    # private
      def set_exclusive_lock
        raise SwtkErrors::LockResourceFailed.new("Not locked in correct way!") if @current_user_id.blank? && @current_job_uid.blank?
        target_lock = SwtkLock.new({
          locked_mode: 1,
          locked_owner: @current_user_id,
          resource_type: self.class.to_s,
          resource_id: self.id.to_s,
          job_uid: @current_job_uid
        })
        target_lock.save!
        return target_lock
      end

      def set_share_lock
        raise SwtkErrors::LockResourceFailed.new("Not locked in correct way!") if @current_user_id.blank? && @current_job_uid.blank?
        if share_lock?
          target_lock = swtk_lock
          
          locked_owner_arr = swtk_lock.locked_owner.split(",")
          locked_owner_arr.push(@current_user_id) if @current_user_id

          job_uid_arr = swtk_lock.job_uid.split(",")
          job_uid_arr.push(@current_job_uid) if @current_job_uid

          target_lock.update({
            locked_times: swtk_lock.locked_times + 1,
            locked_owner: locked_owner_arr.join(","),
            job_uid: job_uid_arr.join(",")
          })
        else
          target_lock = SwtkLock.new({
            locked_mode: 2,
            locked_owner: @current_user_id,
            resource_type: self.class.to_s,
            resource_id: self.id.to_s,
            job_uid: @current_job_uid
          })
          target_lock.save!
        end
        return target_lock
      end

      # 检查是否拍他锁
      def check_lock_if_change!
        raise SwtkErrors::ExclusiveLocking.new("Already locked exclusively!") if exclusive_locked_by_others?
        raise SwtkErrors::ShareLocking.new("Shared locking, update is forbidden!") if share_lock?
      end


      # 判断当前排他锁定对象的条件
      def exclusive_locked_by_current_operator?
        exclusive_lock? && locked_by_current_operator?
      end

      # 判断当前排他锁定对象的条件
      def share_locked_by_current_operator?
        share_lock? && locked_by_current_operator?
      end

      # 判断当前排他锁定对象的条件
      def exclusive_locked_by_others?
        exclusive_lock? && !locked_by_current_operator?
      end

      # 判断当前排他锁定对象的条件
      def share_locked_by_others?
        share_lock? && !locked_by_current_operator?
      end

      # 判断当前锁定对象的条件
      def locked_by_current_operator?
        return false unless locked?
        return swtk_lock.locked_owner.split(",").include?(@current_user_id.to_s) if @current_user_id
        return swtk_lock.job_uid.split(",").include?(@current_job_uid.to_s) if @current_job_uid
        return true
      end
  end
end