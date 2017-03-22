# -*- coding: UTF-8 -*-

class EmptyWorker
  include Sidekiq::Worker

  def perform(*args) 
  end
end
