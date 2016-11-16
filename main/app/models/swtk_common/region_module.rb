module RegionModule
  module Area
    module_function
    
    CountryRids = {
      "zhong_guo" => "001"
      # add other country here
    }

    module Type
      Province = "province"
      City = "city"
      District = "district"
      List = {
        :province => Common::Locale::i18n("dict.province"),
        :city => Common::Locale::i18n("dict.city"),
        :district => Common::Locale::i18n("dict.district")
      }
    end
  end
end