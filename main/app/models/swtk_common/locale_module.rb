module LocaleModule
  module Locale
    module_function

    def i18n label_str,options={}
      if !label_str.blank?
        arr = label_str.scan(/(.*)(\.)$/).first
        label_str = "common.none" if !arr.blank? && (arr[-1] == ".")
      else
        label_str = nil
      end

      options.merge!({:default => label_str.blank?? I18n.t("common.minus") : label_str })
      options.merge!({:locale => :zh}) if options[:locale].blank?
      I18n.t(label_str, options)
    end

    DimesionOrder = {
      "knowledge" => "1",
      "skill" => "2",
      "ability" => "3",
    }

    StatusOrder = {
      :new => "1",
      :editting => "2",
      :editted => "3",
      :analyzing => "4",
      :analyzed => "5",
      :score_importing => "6",
      :score_imported => "7",
      :report_generating => "8",
      :report_completed => "9",
      :none => "10000"
    }

    TenantTypeOrder = {
      :gong_ban_xue_xiao => "1",
      :min_ban_xue_xiao => "2",
      :si_li_xue_xiao => "3",
      :guo_ji_xue_xiao => "4",
      :xue_xiao_lian_he => "5",
      :jiao_yu_ju => "6",
      :others => "7"
    }

    SexList = {
      :wu => i18n("common.none"),
    	:nan => i18n("dict.nan"),
    	:n̈u => i18n("dict.n̈u")
    }

    HttpMethod = %W{
      GET
      POST
      PUT
      PATCH
      DELETE
    }

    def hanzi2pinyin hanzi_str
      PinYin.backend = PinYin::Backend::Simple.new
      PinYin.of_string(hanzi_str).join("_")
    end

    def hanzi2abbrev shanzi_str
      PinYin.backend = PinYin::Backend::Simple.new
      PinYin.abbr(shanzi_str) 
    end

    EMOJIRANGE = Regexp.new("[\u{1F300}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{1F1E6}-\u{1F1FF}
\u231A\u231B\u23E9-\u23EC\u23F0\u23F3
\u2614\u2615\u2648-\u2653\u267F\u2693\u26A1\u26AA\u26AB\u26B3-\u26BD\u26BF-\u26E1\u26E3-\u26FF
\u2705\u270A\u270B\u2728\u274C\u274E\u2753\u2757\u2795\u2796\u2797\u27B0\u27BF
\u{1F1E6}-\u{1F1FF}]")

    def mysort(x,y)
      x = x || ""
      y = y || ""
      length = (x.length > y.length) ? x.length : y.length
      x = x.rjust(length, '0')
      y = y.rjust(length, '0')
      0.upto(length-1) do |i|
        if x[i] == y[i]
          next
        else
          if x[i] =~ /[0-9]/
            if y[i] =~ /[0-9]/
              return x[i] <=> y[i]
            else
              return 1
            end
          elsif y[i] =~ /[0-9]/
            return  -1
          else
            return x[i] <=> y[i]
          end
        end
      end
    end
  end
end
