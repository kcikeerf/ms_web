# -*- coding: UTF-8 -*-

module Mongodb
  code_file = Rails.root + "config/initializers/patches/mongodb_patch.txt"
  begin
    eval(TkEncryption::codes_str_decryption(code_file))
  rescue Exception => ex
    #
  end
end