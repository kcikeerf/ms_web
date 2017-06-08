# -*- coding: UTF-8 -*-

class OnlineTestScheduledGenerateGroupReportsWorker
  include Sidekiq::Worker

  def perform(*args)
    logger = Sidekiq::Logging.logger
    Common::process_sync_template(__method__.to_s()) {|pids|
      pids << fork do # fork new process, begin
        params = args[0]
        target_test_id = params["test_id"]
        target_test = Mongodb::BankTest.where(id: target_test_id).first
        target_test_type =target_test.checkpoint_system.sys_type
        target_dimesions_arr = Common::CheckpointCkp::Dimesions[target_test_type.to_sym]

        job_base_params = {
          :test_id => target_test_id,
          :top_group => params["top_group"]
        }
        rpt_config = Common::Report2::Config

        if target_test.is_public
          Superworker.define(:GeneratePublicOnlineTestGroupReportsSuperWorker, :test_id, :dimesions_arr, :rpt_config, :target_test_type) do
            OnlineTestPrepareReportsDataWorker :test_id, :dimesions_arr
            OnlineTestGenerateGroupReportsWorker :test_id, Common::Report2::Group::Project, nil, :rpt_config, :target_test_type
            OnlineTestConstructReportsWorker :test_id, Common::Report2::Group::Project, nil, :target_test_type
            OnlineTestClearReportsGarbageWorker :test_id
          end
          GeneratePublicOnlineTestGroupReportsSuperWorker.perform_async(target_test_id)
        else
          tenant_uids = target_test.tenants.map(&:uid)
          Superworker.define(:GeneratePrivateOnlineTestGroupReportsSuperWorker, :test_id, :tenant_uids, :dimesions_arr, :rpt_config, :target_test_type) do
            OnlineTestPrepareReportsDataWorker :test_id, :dimesions_arr
            EmptyWorker do
              parallel do
                batch tenant_uids: :tenant_uid do
                  parallel do
                    OnlineTestGenerateGroupReportsWorker :test_id, Common::Report2::Group::Klass, :tenant_uid, :rpt_config, :target_test_type
                    OnlineTestGenerateGroupReportsWorker :test_id, Common::Report2::Group::Grade, :tenant_uid, :rpt_config, :target_test_type
                  end
                end
                if job_base_params[:top_group] == Common::Report2::Group::Project
                  OnlineTestGenerateGroupReportsWorker :test_id, Common::Report2::Group::Project, nil, :rpt_config, :target_test_type
                end
              end
            end
            EmptyWorker do
              parallel do
                batch tenant_uids: :tenant_uid do
                  parallel do
                    OnlineTestConstructReportsWorker :test_id, Common::Report2::Group::Klass, :tenant_uid, :target_test_type
                    OnlineTestConstructReportsWorker :test_id, Common::Report2::Group::Grade, :tenant_uid, :target_test_type
                  end
                end
                if job_base_params[:top_group] == Common::Report2::Group::Project
                  OnlineTestConstructReportsWorker :test_id, Common::Report2::Group::Project, nil, :target_test_type
                end
              end
            end
            OnlineTestClearReportsGarbageWorker :test_id
          end
          GeneratePrivateOnlineTestGroupReportsSuperWorker.perform_async(target_test_id,tenant_uids, target_dimesions_arr, rpt_config, target_test_type)
        end
        
      end # fork new process, end
    } 
  end
end
