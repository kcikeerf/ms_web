# -*- coding: UTF-8 -*-

class OnlineTestConstructReportsWorker
  include Sidekiq::Worker

  def perform(*args)
    logger = Sidekiq::Logging.logger
    Common::process_sync_template(__method__.to_s()) {|pids|
      pids << fork do # fork new process, begin
 		logger.info "OnlineTestConstructReportsWorker"
      end # fork new process, end
    } 
  end
end
