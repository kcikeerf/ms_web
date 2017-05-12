module KlassModule
  module Klass
    module_function
    KlassArr = %W{
      yi_ban
      er_ban
      san_ban 
      si_ban
      wu_ban
      liu_ban 
      qi_ban
      ba_ban
      jiu_ban 
      shi_ban 
      shi_yi_ban
      shi_er_ban
      shi_san_ban 
      shi_si_ban
      shi_wu_ban
      shi_liu_ban 
      shi_qi_ban
      shi_ba_ban
      shi_jiu_ban 
      er_shi_ban
      er_shi_yi_ban
      er_shi_er_ban
      er_shi_san_ban 
      er_shi_si_ban
      er_shi_wu_ban
      er_shi_liu_ban 
      er_shi_qi_ban
      er_shi_ba_ban
      er_shi_jiu_ban 
      san_shi_ban
      san_shi_yi_ban
      san_shi_er_ban
      san_shi_san_ban
      san_shi_si_ban
      san_shi_wu_ban
      san_shi_liu_ban
      san_shi_qi_ban
      san_shi_ba_ban
      san_shi_jiu_ban
      si_shi_ban
      si_shi_yi_ban
      si_shi_er_ban
      si_shi_san_ban
      si_shi_si_ban
      si_shi_wu_ban
      si_shi_liu_ban
      si_shi_qi_ban
      si_shi_ba_ban
      si_shi_jiu_ban
      wu_shi_ban
      wu_shi_yi_ban
      wu_shi_er_ban
      wu_shi_san_ban
      wu_shi_si_ban 
      wu_shi_wu_ban
      wu_shi_liu_ban
      wu_shi_qi_ban
      wu_shi_ba_ban
      wu_shi_jiu_ban
      liu_shi_ban
      liu_shi_yi_ban
      liu_shi_er_ban
      liu_shi_san_ban
      liu_shi_si_ban
      liu_shi_wu_ban
      liu_shi_liu_ban
      liu_shi_qi_ban
      liu_shi_ba_ban
      liu_shi_jiu_ban
      qi_shi_ban
      qi_shi_yi_ban
      qi_shi_er_ban
      qi_shi_san_ban
      qi_shi_si_ban
      qi_shi_wu_ban
      qi_shi_liu_ban
      qi_shi_qi_ban
      qi_shi_ba_ban
      qi_shi_jiu_ban
      ba_shi_ban
      ba_shi_yi_ban
      ba_shi_er_ban
      ba_shi_san_ban
      ba_shi_si_ban
      ba_shi_wu_ban
      ba_shi_liu_ban
      ba_shi_qi_ban
      ba_shi_ba_ban 
      ba_shi_jiu_ban
      jiu_shi_ban
      jiu_shi_yi_ban
      jiu_shi_er_ban
      jiu_shi_san_ban
      jiu_shi_si_ban
      jiu_shi_wu_ban
      jiu_shi_liu_ban
      jiu_shi_qi_ban
      jiu_shi_ba_ban
      jiu_shi_jiu_ban
      yi_bai_ban 
    }

    List = {}
    Order = {}
    KlassArr.each_with_index{|item, index|
      List[item.to_sym] = Common::Locale::i18n("dict.#{item}")
      Order[item] = (index + 1).to_s
    }

    def klass_label klassroom
      klassroom.nil?? "":Common::Klass::List.keys.include?(klassroom.to_sym) ? Common::Locale::i18n("dict.#{klassroom}") : klassroom
    end
  end
end