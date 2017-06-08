# -*- coding: UTF-8 -*-

require 'thwait'

module ReportPlus2Module
  module ReportPlus2
    module_function
    
    code_file = Rails.root + "config/initializers/patches/report_plus2_patch.txt"
    begin
      eval(TkEncryption::codes_str_decryption(code_file,1))
    rescue Exception => ex
      #
    end

  end  
end
