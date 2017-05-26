# -*- coding: UTF-8 -*-

class OnlineTestScheduledGenerateGroupReportsWorker
  include Sidekiq::Worker

  def perform(*args)
    logger = Sidekiq::Logging.logger
    Common::process_sync_template(__method__.to_s()) {|pids|
      pids << fork do # fork new process, begin
        params = args[0]
        target_test = Mongodb::BankTest.where(id: params["test_id"]).first
        if target_test.is_public
          Superworker.define(:GeneratePublicOnlineTestGroupReportsSuperWorker, :test_id) do
            OnlineTestPrepareReportsDataWorker :test_id
            OnlineTestGenerateGroupReportsWorker :test_id, "project"
            OnlineTestConstructReportsWorker :test_id, "project"
            OnlineTestClearReportsGarbageWorker :test_id
          end
          GenerateOnlineTestGroupReportsSuperWorker.perform_async(params["test_id"])
        else
          tenant_uids = target_test.tenants.map(&:uid)
          Superworker.define(:GeneratePrivateOnlineTestGroupReportsSuperWorker, :test_id, :tenant_uids) do
            OnlineTestPrepareReportsDataWorker :test_id
            OnlineTestGenerateGroupReportsWorker :test_id #.new.perform
            OnlineTestConstructReportsWorker :test_id #.new.perform
            OnlineTestClearReportsGarbageWorker :test_id #.new.perform

            EmptyWorker do
              parallel do
                batch tenant_uids: :tenant_uid do
                  parallel do
                    OnlineTestGenerateGroupReportsWorker :test_id, Common::Report2::Group::Klass, :tenant_uid
                    OnlineTestGenerateGroupReportsWorker :test_id, Common::Report2::Group::Grade, :tenant_uid
                  end
                end
                if job_base_params[:top_group] == Common::Report2::Group::Project
                  OnlineTestGenerateGroupReportsWorker :test_id, Common::Report2::Group::Project, nil
                end
              end
            end
            EmptyWorker do
              parallel do
                batch tenant_uids: :tenant_uid do
                  parallel do
                    OnlineTestConstructReportsWorker :test_id, Common::Report2::Group::Klass, :tenant_uid
                    OnlineTestConstructReportsWorker :test_id, Common::Report2::Group::Grade, :tenant_uid
                  end
                end
                if job_base_params[:top_group] == Common::Report2::Group::Project
                  OnlineTestConstructReportsWorker :test_id, Common::Report2::Group::Project, nil
                end
              end
            end
            OnlineTestClearReportsGarbageWorker :test_id
          end
          GenerateOnlineTestGroupReportsSuperWorker.perform_async(params["test_id"],tenant_uids)
        end
        
      end # fork new process, end
    } 
  end
end
