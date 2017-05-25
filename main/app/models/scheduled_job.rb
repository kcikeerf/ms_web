# -*- coding: UTF-8 -*-

class ScheduledJob < ActiveRecord::Base
  self.primary_key = "uid"
  #concerns
  include InitUid
end
