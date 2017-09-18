# -*- coding: UTF-8 -*-

class Mongodb::TestReportUrl
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  index({_id: 1}, {background: true})
  index({test_id: 1}, {background: true})
  index({report_url: 1}, {background: true})
end