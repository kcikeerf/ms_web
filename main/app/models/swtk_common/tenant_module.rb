module TenantModule
  module Tenant
    NumberLength = 5
    NumberRandArr = [*'A'..'Z']
    TypeList = {
      :gong_ban_xue_xiao => I18n.t("tenants.types.gong_ban_xue_xiao"),
      :min_ban_xue_xiao => I18n.t("tenants.types.min_ban_xue_xiao"),
      :si_li_xue_xiao => I18n.t("tenants.types.si_li_xue_xiao"),
      :guo_ji_xue_xiao => I18n.t("tenants.types.guo_ji_xue_xiao"),
      :xue_xiao_lian_he => I18n.t("tenants.types.xue_xiao_lian_he"),
      :jiao_yu_ju => I18n.t("tenants.types.jiao_yu_ju"),
      :others => I18n.t("tenants.types.others")
    }
  end
end