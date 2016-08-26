# -*- coding: UTF-8 -*-

class ImportScoreJob < ActiveJob::Base
  queue_as :score

  def self.perform_later(*args)
    begin
      params = args[0]
      logger.info "============>>Import Score Job: Begin<<=============="



    rescue Exception => ex
      logger.info "===!Excepion!==="
      logger.info "[message]"
      logger.warn ex.message
      logger.info "[backtrace]"
      logger.warn ex.backtrace
    ensure 
      logger.info "============>>Import Score Job: End<<=============="
    end
  end
end
