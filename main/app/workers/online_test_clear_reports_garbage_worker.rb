# -*- coding: UTF-8 -*-

class OnlineTestClearReportsGarbageWorker
  include Sidekiq::Worker

  def perform(*args)
    logger = Sidekiq::Logging.logger
    Common::process_sync_template(__method__.to_s()) {|pids|
      pids << fork do # fork new process, begin
        logger.info "#{args}"
        if !args.blank?
          report_redis_key_wildcard = Common::SwtkRedis::Prefix::Reports + "tests/" + args[0] + "/*"
          report_redis_keys = Common::SwtkRedis::find_keys(Common::SwtkRedis::Ns::Sidekiq, report_redis_key_wildcard)
          report_redis_keys.each{|key| Common::SwtkRedis::current_redis(Common::SwtkRedis::Ns::Sidekiq).del(key) }
        else
          raise SwtkErrors::ParameterInvalidError.new(Common::Locale::i18n("swtk_errors.parameter_invalid_error", :message => ""))
        end
      end # fork new process, end
    } 
  end
end
