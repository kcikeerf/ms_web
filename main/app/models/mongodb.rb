# -*- coding: UTF-8 -*-

module Mongodb

  def self.table_name_prefix
    'mongodb_'
  end

  def self.included(base)
    others = {
      "TestReportUrl" => %Q{
        include Mongoid::Document
        include Mongoid::Attributes::Dynamic

        index({_id: 1}, {background: true})
        index({test_id: 1}, {background: true})
        index({report_url: 1}, {background: true})
      }
    }
    others.each{|klass, core_str|
      self.const_set(klass, Class.new)
      ("Mongodb::" + klass).constantize.class_eval do
        eval(core_str)
      end
    }
  end
end