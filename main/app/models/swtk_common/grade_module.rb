module GradeModule
  module Grade
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

    XueDuanList = {
      :xiao_xue => Common::Locale::i18n("checkpoints.subject.category.xiao_xue"),
      :chu_zhong => Common::Locale::i18n("checkpoints.subject.category.chu_zhong"),
      :gao_zhong => Common::Locale::i18n("checkpoints.subject.category.gao_zhong")
    }

    XiaoXue = ["yi_nian_ji", "er_nian_ji", "san_nian_ji", "si_nian_ji", "wu_nian_ji", "liu_nian_ji"]
    ChuZhong = ["qi_nian_ji", "ba_nian_ji", "jiu_nian_ji"]
    GaoZhong = ["gao_yi_nian_ji", "gao_er_nian_ji", "gao_san_nian_ji"]
  end
end