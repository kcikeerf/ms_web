module TkLockModule
  module TkLock
    module_function

    ReadOnly=1
    WriteOnly=2
    ReadWrite=3

 
    def share_lock_paper_test_qzp_ckp _test_id, _user_id=nil, _job_uid=nil
      target_test = Mongodb::BankTest.where(id: _test_id).first
      target_paper = target_test.bank_paper_pap
      paper_qzps = target_paper.bank_quiz_qizs.map{|qiz| qiz.bank_qizpoint_qzps}.flatten.compact
      ckps = paper_qzps.map{|qzp| qzp.bank_checkpoint_ckps}.flatten.uniq.compact

      # 验证资源锁状态
      # 测试
      raise SwtkErrors::LockResourceFailed.new(Common::Locale::i18n("swtk_errors.lock_resource_failed", :message => "test: #{@target_test.id.to_s}")) if target_test.exclusive_lock?
      target_test.set_operator(_user_id, _job_uid)
      target_test.acquire_share_lock!
      # 试卷
      raise SwtkErrors::LockResourceFailed.new(Common::Locale::i18n("swtk_errors.lock_resource_failed", :message => "paper: #{target_paper.id.to_s}")) if target_paper.exclusive_lock?
      target_paper.set_operator(_user_id, _job_uid)
      target_paper.acquire_share_lock!
      # 得分点
      paper_qzps.each{|qzp|
        raise SwtkErrors::LockResourceFailed.new(Common::Locale::i18n("swtk_errors.lock_resource_failed", :message => "qizpoint: #{qzp.id.to_s}")) if qzp.exclusive_lock?
        qzp.set_operator(_user_id, _job_uid)
        qzp.acquire_share_lock!
        # # 指标
        # qzp.bank_checkpoint_ckps.each{|ckp|
        #   raise SwtkErrors::LockResourceFailed.new(Common::Locale::i18n("swtk_errors.lock_resource_failed", :message => "check point: #{ckp.id.to_s}")) if ckp.exclusive_lock?
        #   ckp.set_operator(_user_id, _job_uid)
        #   ckp.acquire_share_lock!
        # }
      }
      # 指标
      ckps.each{|ckp|
        raise SwtkErrors::LockResourceFailed.new(Common::Locale::i18n("swtk_errors.lock_resource_failed", :message => "check point: #{ckp.id.to_s}")) if ckp.exclusive_lock?
        ckp.set_operator(_user_id, _job_uid)
        ckp.acquire_share_lock!
      }
    end

    def release_lock_paper_test_qzp_ckp _test_id, _user_id=nil, _job_uid=nil
      target_test = Mongodb::BankTest.where(id: _test_id).first
      target_paper = target_test.bank_paper_pap
      paper_qzps = target_paper.bank_quiz_qizs.map{|qiz| qiz.bank_qizpoint_qzps}.flatten.compact
      ckps = paper_qzps.map{|qzp| qzp.bank_checkpoint_ckps}.flatten.uniq.compact
      
      # 资源解除锁定
      # 测试
      target_test.set_operator(_user_id, _job_uid)
      target_test.release_lock!
      # 试卷
      target_paper.set_operator(_user_id, _job_uid)
      target_paper.release_lock!
      # 得分点
      paper_qzps.each{|qzp|
        qzp.set_operator(_user_id, _job_uid)
        qzp.release_lock!
        # # 指标
        # qzp.bank_checkpoint_ckps.each{|ckp|
        #   ckp.set_operator(_user_id, _job_uid)
        #   ckp.release_lock!
        # }
      }
      # 指标
      ckps.each{|ckp|
        ckp.set_operator(_user_id, _job_uid)
        ckp.release_lock!
      }      
    end

    def force_release_lock_paper_test_qzp_ckp _test_id
      target_test = Mongodb::BankTest.where(id: _test_id).first
      target_paper = target_test.bank_paper_pap
      paper_qzps = target_paper.bank_quiz_qizs.map{|qiz| qiz.bank_qizpoint_qzps}.flatten.compact      
      # 资源解除锁定
      # 测试
      target_test.force_release_lock!
      # 试卷
      target_paper.force_release_lock!
      # 得分点
      paper_qzps.each{|qzp|
        qzp.force_release_lock!
        # 指标
        qzp.bank_checkpoint_ckps.each{|ckp|
          ckp.force_release_lock!
        }
      }
    end

    def show_lock_paper_test_qzp_ckp _test_id
      target_test = Mongodb::BankTest.where(id: _test_id).first
      target_paper = target_test.bank_paper_pap
      paper_qzps = target_paper.bank_quiz_qizs.map{|qiz| qiz.bank_qizpoint_qzps}.flatten.compact      
      # 资源解除锁定
      # 测试
      p ">>>测试, #{target_test.id.to_s}"
      p target_test.locked?
      # 试卷
      p ">>>试卷, #{target_paper.id.to_s}"
      p target_paper.locked?
      # 得分点
      paper_qzps.each{|qzp|
        p ">>>得分点, #{qzp.id.to_s}"
        p qzp.locked?
        # 指标
        qzp.bank_checkpoint_ckps.each{|ckp|
          p ">>>CKP, #{ckp.id.to_s}"
          p ckp.locked?
        }
      }
    end

  end
end