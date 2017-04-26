module TenantModule
  module Tenant
    NumberLength = 5
    NumberRandArr = Common::SwtkConstants::AlphabetDownCaseArr
    TypeList = {
      :gong_ban_xue_xiao => Common::Locale::i18n("tenants.types.gong_ban_xue_xiao"),
      :min_ban_xue_xiao => Common::Locale::i18n("tenants.types.min_ban_xue_xiao"),
      :si_li_xue_xiao => Common::Locale::i18n("tenants.types.si_li_xue_xiao"),
      :guo_ji_xue_xiao => Common::Locale::i18n("tenants.types.guo_ji_xue_xiao"),
      :xue_xiao_lian_he => Common::Locale::i18n("tenants.types.xue_xiao_lian_he"),
      :jiao_yu_ju => Common::Locale::i18n("tenants.types.jiao_yu_ju"),
      :others => Common::Locale::i18n("tenants.types.others")
    }
  end
end