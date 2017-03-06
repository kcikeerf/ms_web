# -*- coding: UTF-8 -*-

require 'thwait'

module ReportPlusModule
  module ReportPlus
    module_function
    code_file = Rails.root + "config/initializers/patches/report_plus_patch.txt"
    begin
      eval(TkEncryption::codes_str_decryption(code_file))
    rescue Exception => ex
      #
    end    
  end
end
