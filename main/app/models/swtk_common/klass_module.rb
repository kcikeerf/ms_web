module KlassModule
  module Klass
    module_function
    List = {
      :yi_ban => Common::Locale::i18n("dict.yi_ban"),
      :er_ban => Common::Locale::i18n("dict.er_ban"),
      :san_ban => Common::Locale::i18n("dict.san_ban"),
      :si_ban => Common::Locale::i18n("dict.si_ban"),
      :wu_ban => Common::Locale::i18n("dict.wu_ban"),
      :liu_ban => Common::Locale::i18n("dict.liu_ban"),
      :qi_ban => Common::Locale::i18n("dict.qi_ban"),
      :ba_ban => Common::Locale::i18n("dict.ba_ban"),
      :jiu_ban => Common::Locale::i18n("dict.jiu_ban"),
      :shi_ban => Common::Locale::i18n("dict.shi_ban"),
      :shi_yi_ban => Common::Locale::i18n("dict.shi_yi_ban"),
      :shi_er_ban => Common::Locale::i18n("dict.shi_er_ban"),
      :shi_san_ban => Common::Locale::i18n("dict.shi_san_ban"),
      :shi_si_ban => Common::Locale::i18n("dict.shi_si_ban"),
      :shi_wu_ban => Common::Locale::i18n("dict.shi_wu_ban"),
      :shi_liu_ban => Common::Locale::i18n("dict.shi_liu_ban"),
      :shi_qi_ban => Common::Locale::i18n("dict.shi_qi_ban"),
      :shi_ba_ban => Common::Locale::i18n("dict.shi_ba_ban"),
      :shi_jiu_ban => Common::Locale::i18n("dict.shi_jiu_ban"),
      :er_shi_ban => Common::Locale::i18n("dict.er_shi_ban"),
      :er_shi_yi_ban => Common::Locale::i18n("dict.er_shi_yi_ban"),
      :er_shi_er_ban => Common::Locale::i18n("dict.er_shi_er_ban"),
      :er_shi_san_ban => Common::Locale::i18n("dict.er_shi_san_ban"),
      :er_shi_si_ban => Common::Locale::i18n("dict.er_shi_si_ban"),
      :er_shi_wu_ban => Common::Locale::i18n("dict.er_shi_wu_ban"),
      :er_shi_liu_ban => Common::Locale::i18n("dict.er_shi_liu_ban"),
      :er_shi_qi_ban => Common::Locale::i18n("dict.er_shi_qi_ban"),
      :er_shi_ba_ban => Common::Locale::i18n("dict.er_shi_ba_ban"),
      :er_shi_jiu_ban => Common::Locale::i18n("dict.er_shi_jiu_ban"),
      :san_shi_ban => Common::Locale::i18n("dict.san_shi_ban")
    }

    Order ={
      "yi_ban" => "1",
      "er_ban" => "2",
      "san_ban" => "3",
      "si_ban" => "4",
      "wu_ban" => "5",
      "liu_ban" => "6",
      "qi_ban" => "7",
      "ba_ban" => "8",
      "jiu_ban" => "9",
      "shi_ban" => "10",
      "shi_yi_ban" => "11",
      "shi_er_ban" => "12",
      "shi_san_ban" => "13",
      "shi_si_ban" => "14",
      "shi_wu_ban" => "15",
      "shi_liu_ban" => "16",
      "shi_qi_ban" => "17",
      "shi_ba_ban" => "18",
      "shi_jiu_ban" => "19",
      "er_shi_ban" => "20",
      "er_shi_yi_ban" => "21",
      "er_shi_er_ban" => "22",
      "er_shi_san_ban" => "23",
      "er_shi_si_ban" => "24",
      "er_shi_wu_ban" => "25",
      "er_shi_liu_ban" => "26",
      "er_shi_qi_ban" => "27",
      "er_shi_ba_ban" => "28",
      "er_shi_jiu_ban" => "29",
      "san_shi_ban" => "30"
    }

    def klass_label klassroom
      klassroom.nil?? "":Common::Klass::List.keys.include?(klassroom.to_sym) ? Common::Locale::i18n("dict.#{klassroom}") : klassroom
    end
  end
end