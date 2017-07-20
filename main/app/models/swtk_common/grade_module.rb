module GradeModule
  module Grade
    module_function
    
    Order = {
      :yi_nian_ji => "1",
      :er_nian_ji => "2",
      :san_nian_ji => "3",
      :si_nian_ji => "4",
      :wu_nian_ji => "5",
      :liu_nian_ji => "6",
      :qi_nian_ji => "7",
      :ba_nian_ji => "8",
      :jiu_nian_ji => "9",
      :gao_yi_nian_ji => "10",
      :gao_er_nian_ji => "11",
      :gao_san_nian_ji => "12",
      :none => "10000"
    }

    List = {
      :yi_nian_ji => Common::Locale::i18n("dict.yi_nian_ji"),
      :er_nian_ji => Common::Locale::i18n("dict.er_nian_ji"),
      :san_nian_ji => Common::Locale::i18n("dict.san_nian_ji"),
      :si_nian_ji => Common::Locale::i18n("dict.si_nian_ji"),
      :wu_nian_ji => Common::Locale::i18n("dict.wu_nian_ji"),
      :liu_nian_ji => Common::Locale::i18n("dict.liu_nian_ji"),
      :qi_nian_ji => Common::Locale::i18n("dict.qi_nian_ji"),
      :ba_nian_ji => Common::Locale::i18n("dict.ba_nian_ji"),
      :jiu_nian_ji => Common::Locale::i18n("dict.jiu_nian_ji"),
      :gao_yi_nian_ji => Common::Locale::i18n("dict.gao_yi_nian_ji"),
      :gao_er_nian_ji => Common::Locale::i18n("dict.gao_er_nian_ji"),
      :gao_san_nian_ji => Common::Locale::i18n("dict.gao_san_nian_ji")
    }

    module XueDuan
      Order = {
        :xiao_xue => "1",
        :chu_zhong => "2",
        :gao_zhong => "3",
      }

      List = {
        :xiao_xue => Common::Locale::i18n("checkpoints.subject.category.xiao_xue"),
        :chu_zhong => Common::Locale::i18n("checkpoints.subject.category.chu_zhong"),
        :gao_zhong => Common::Locale::i18n("checkpoints.subject.category.gao_zhong")
      }
      Range = {
        :xiao_xue => ["yi_nian_ji", "er_nian_ji", "san_nian_ji", "si_nian_ji", "wu_nian_ji", "liu_nian_ji"],
        :chu_zhong => ["qi_nian_ji", "ba_nian_ji", "jiu_nian_ji"],
        :gao_zhong => ["gao_yi_nian_ji", "gao_er_nian_ji", "gao_san_nian_ji"]
      }

      XiaoXue = "xiao_xue"
      ChuZhong = "chu_zhong"
      GaoZhong = "gao_zhong"
    end

    # 获取学段
    def judge_xue_duan target_grade
      result = nil
      if XueDuan::Range[:xiao_xue].include? target_grade
        result = XueDuan::XiaoXue
      elsif XueDuan::Range[:chu_zhong].include? target_grade
        result = XueDuan::ChuZhong
      elsif XueDuan::Range[:gao_zhong].include? target_grade
        result = XueDuan::GaoZhong
      end
      return result   
    end

  end
end