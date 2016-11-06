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
      [
        "Report#{t}BaseResult",
        "Report#{t}Lv1CkpResult",
        "Report#{t}Lv2CkpResult",
        "Report#{t}LvEndCkpResult",
        "Report#{t}OrderResult",
        "Report#{t}OrderLv1CkpResult",
        "Report#{t}OrderLv2CkpResult",
        "Report#{t}OrderLvEndCkpResult"
      ]
    }

    pupil_stat_klass_arr = []
    pupil_stat_klass_arr += group_types[1..-1].map{|t|
      [
        "Report#{t}BeforeBasePupilStatResult",
        "Report#{t}BeforeLv1CkpPupilStatResult",
        "Report#{t}BeforeLv2CkpPupilStatResult",
        "Report#{t}BeforeLvEndCkpPupilStatResult",
        "Report#{t}BasePupilStatResult",
        "Report#{t}Lv1CkpPupilStatResult",
        "Report#{t}Lv2CkpPupilStatResult",
        "Report#{t}LvEndCkpPupilStatResult"
      ]
    }

    #
    klass_arr = klass_version_1_0_arr + base_result_klass_arr.flatten + pupil_stat_klass_arr.flatten
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