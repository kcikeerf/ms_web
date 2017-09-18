# -*- coding: UTF-8 -*-

class Mongodb::UnionTestReportUrl
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  index({_id: 1}, {background: true})
  index({union_test_id: 1}, {background: true})
  index({report_url: 1}, {background: true})
end