# -*- coding: UTF-8 -*-

class Mongodb::OnlineTestZhFzqnGroupConstructor
  include Mongoid::Document

  code_file = Rails.root + "config/initializers/patches/mongodb_online_test_zh_fzqn_group_constructor_patch.txt"
  begin
    eval(TkEncryption::codes_str_decryption(code_file,1))
  rescue Exception => ex
    #
  end

end
