# -*- coding: UTF-8 -*-

class Mongodb::ReportPupilGenerator
  include Mongoid::Document
  code_file = Rails.root + "config/initializers/patches/mongodb_report_pupil_generator_patch.txt"
  begin
    eval(TkEncryption::codes_str_decryption(code_file))
  rescue Exception => ex
    #
  end
end
