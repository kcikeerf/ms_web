# -*- coding: UTF-8 -*-

class OnlineTestScheduledGenerateGroupReportsWorker
  include Sidekiq::Worker

  def perform(*args)
    logger = Sidekiq::Logging.logger
    Common::process_sync_template(__method__.to_s()) {|pids|
      pids << fork do # fork new process, begin
 		 logger.info "OnlineTestScheduledGenerateGroupReportsWorker"

        #Superworker.define(:GenerateReportSuperWorker) do
            OnlineTestPrepareReportsDataWorker.new.perform
            OnlineTestGenerateGroupReportsWorker.new.perform
            OnlineTestConstructReportsWorker.new.perform
            OnlineTestClearReportsGarbageWorker.new.perform
            ClearReportsGarbageWorker.new.perform(["",""])
        #end
        #GenerateReportSuperWorker.perform_async()
      end # fork new process, end
    } 
  end
end
