# -*- coding: UTF-8 -*-

module Mongodb
  def self.table_name_prefix
    'mongodb_'
  end

  def self.included(base)
    #version1.0
    klass_version_1_0_arr = [
      "ReportEachLevelPupilNumberResult",
      "ReportFourSectionPupilNumberResult",
      "ReportStandDevDiffResult",
      "ReportTotalAvgResult",
      "ReportQuizCommentsResult",
      "MobileReportTotalAvgResult",
      "MobileReportBasedOnTotalAvgResult",
    ]
    
    #version1.1
    group_types = Common::Report::Group::ListArr
    base_result_klass_arr = []
    base_result_klass_arr += group_types.map{|t|
      collect_type = t.capitalize 
      [
        "Report#{collect_type}BaseResult",
        "Report#{collect_type}Lv1CkpResult",
        "Report#{collect_type}Lv2CkpResult",
        "Report#{collect_type}LvEndCkpResult",
        "Report#{collect_type}OrderResult",
        "Report#{collect_type}OrderLv1CkpResult",
        "Report#{collect_type}OrderLv2CkpResult",
        "Report#{collect_type}OrderLvEndCkpResult"
      ]
    }

    pupil_stat_klass_arr = []
    pupil_stat_klass_arr += group_types[1..-1].map{|t|
      collect_type = t.capitalize 
      [
        "Report#{collect_type}BeforeBasePupilStatResult",
        "Report#{collect_type}BeforeLv1CkpPupilStatResult",
        "Report#{collect_type}BeforeLv2CkpPupilStatResult",
        "Report#{collect_type}BeforeLvEndCkpPupilStatResult",
        "Report#{collect_type}BasePupilStatResult",
        "Report#{collect_type}Lv1CkpPupilStatResult",
        "Report#{collect_type}Lv2CkpPupilStatResult",
        "Report#{collect_type}LvEndCkpPupilStatResult"
      ]
    }

    online_test_types = Common::OnrineTest::Group::List

    online_test_klass_arr = online_test_types.map{|t|
      collect_type = t.capitalize 
      [
        "OnlineTestReport#{collect_type}BaseResult",
        "OnlineTestReport#{collect_type}Lv1CkpResult",
        "OnlineTestReport#{collect_type}Lv2CkpResult",
        "OnlineTestReport#{collect_type}LvEndCkpResult",
        "OnlineTestReport#{collect_type}OrderResult",
        "OnlineTestReport#{collect_type}OrderLv1CkpResult",
        "OnlineTestReport#{collect_type}OrderLv2CkpResult",
        "OnlineTestReport#{collect_type}OrderLvEndCkpResult"
      ]
    }

    online_test_pupil_stat_klass_arr = [
        "OnlineTestReportTotalBeforeBasePupilStatResult",
        "OnlineTestReportTotalBeforeLv1CkpPupilStatResult",
        "OnlineTestReportTotalBeforeLv2CkpPupilStatResult",
        "OnlineTestReportTotalBeforeLvEndCkpPupilStatResult"
    ]

    #
    klass_arr = [
      klass_version_1_0_arr,
      base_result_klass_arr, 
      pupil_stat_klass_arr,
      online_test_klass_arr,
      online_test_pupil_stat_klass_arr
      ].flatten
    
    klass_arr.each{|klass|
      self.const_set(klass, Class.new)
      "Mongodb::#{klass}".constantize.class_eval do
        include Mongoid::Document
        include Mongoid::Attributes::Dynamic

        index({_id: 1}, {background: true})
      end
    }
  end
end