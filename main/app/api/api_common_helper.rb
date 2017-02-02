# -*- coding: UTF-8 -*-

module ApiCommonHelper
  def message_json code,options={}
    {
      code: code,
      message: Common::Locale::i18n.t("api.#{code}", options)
    }
  end
end