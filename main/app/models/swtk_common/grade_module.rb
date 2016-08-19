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
      :yi_nian_ji => I18n.t("dict.yi_nian_ji"),
      :er_nian_ji => I18n.t("dict.er_nian_ji"),
      :san_nian_ji => I18n.t("dict.san_nian_ji"),
      :si_nian_ji => I18n.t("dict.si_nian_ji"),
      :wu_nian_ji => I18n.t("dict.wu_nian_ji"),
      :liu_nian_ji => I18n.t("dict.liu_nian_ji"),
      :qi_nian_ji => I18n.t("dict.qi_nian_ji"),
      :ba_nian_ji => I18n.t("dict.ba_nian_ji"),
      :jiu_nian_ji => I18n.t("dict.jiu_nian_ji"),
      :gao_yi_nian_ji => I18n.t("dict.gao_yi_nian_ji"),
      :gao_er_nian_ji => I18n.t("dict.gao_er_nian_ji"),
      :gao_san_nian_ji => I18n.t("dict.gao_san_nian_ji")
    }

    XiaoXue = ["yi_nian_ji", "er_nian_ji", "san_nian_ji", "si_nian_ji", "wu_nian_ji", "liu_nian_ji"]
    ChuZhong = ["qi_nian_ji", "ba_nian_ji", "jiu_nian_ji"]
    GaoZhong = ["gao_yi_nian_ji", "gao_er_nian_ji", "gao_san_nian_ji"]
  end
end