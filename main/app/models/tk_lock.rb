# -*- coding: UTF-8 -*-

class TkLock < ActiveRecord::Base
  belongs_to :lock_resource, polymorphic: true
end
