module SkopeModule
  module Skope
    
  end

  module SkopeRule
    DefaultKeyListArr = [
      {rkey: "province", rkey_label: Common::Locale::i18n("dict.province")},
      {rkey: "city", rkey_label: Common::Locale::i18n("dict.city")},
      {rkey: "district", rkey_label: Common::Locale::i18n("dict.district")},
      {rkey: "tenant", rkey_label: Common::Locale::i18n("dict.tenant") + "(#{Common::Locale::i18n("dict.school")})"},
      {rkey: "klass", rkey_label: Common::Locale::i18n("dict.classroom")},
      {rkey: "pupil", rkey_label: Common::Locale::i18n("dict.pupil")},
      {rkey: "subject", rkey_label: Common::Locale::i18n("dict.subject")},
      {rkey: "grade", rkey_label: Common::Locale::i18n("dict.grade")}
    ]

    DefaultKeyList = {
      "province" => Common::Locale::i18n("dict.province"),
      "city" => Common::Locale::i18n("dict.city"),
      "district" => Common::Locale::i18n("dict.district"),
      "tenant" => Common::Locale::i18n("dict.tenant") + "(#{Common::Locale::i18n("dict.school")})",
      "klass" => Common::Locale::i18n("dict.classroom"),
      "pupil" => Common::Locale::i18n("dict.pupil"),
      "subject" => Common::Locale::i18n("dict.subject"),
      "grade" => Common::Locale::i18n("dict.grade")
    }

    DefaultValueListArr = [
      {rvalue: "-1", rvalue_label: Common::Locale::i18n("managers.skope_rules.all_invalid")},
      {rvalue: "1", rvalue_label: Common::Locale::i18n("managers.skope_rules.specified_available")},
      {rvalue: "99", rvalue_label: Common::Locale::i18n("managers.skope_rules.all_available")}      
    ]

    DefaultValueList = {
      "-1" => Common::Locale::i18n("managers.skope_rules.all_invalid"),
      "1" => Common::Locale::i18n("managers.skope_rules.specified_available"),
      "99" => Common::Locale::i18n("managers.skope_rules.all_available")     
    }
  end
end
