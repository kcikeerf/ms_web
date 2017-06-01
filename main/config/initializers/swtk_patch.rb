#swtk user patch
require 'openssl'

class Hash
  def insert_before(key, arr)
    arr = to_a
    pos = arr.index(arr.assoc(key))
    if pos
      arr.insert(pos, arr)
    else
      arr << arr
    end
    replace Hash[arr]
  end
end

class Array
  def insert_before(key, kvpair)
    pos = index(assoc(key))
    if pos
      insert(pos, kvpair)
    else
      self << kvpair
    end
  end
end


class String
  $pass_phrase = "7cdcde8c-fe3b-11e6-afd0-00163e321126"
  $salt = "tksecret"

  def encrypt(pass_phrase=$pass_phrase,salt=$salt)
    encrypter = OpenSSL::Cipher.new 'AES-128-CFB'
    encrypter.encrypt
    encrypter.pkcs5_keyivgen pass_phrase, salt
    encrypted = encrypter.update self
    encrypted << encrypter.final
    Base64.encode64(encrypted).encode('utf-8') 
  end

  def decrypt(pass_phrase=$pass_phrase,salt=$salt)
    decrypter = OpenSSL::Cipher.new 'AES-128-CFB'
    decrypter.decrypt
    decrypter.pkcs5_keyivgen pass_phrase, salt
    target = Base64.decode64(self.encode('ascii-8bit') )
    plain = decrypter.update target
    plain << decrypter.final
  end
end

module TkEncryption
  module_function
  def codes_str_decryption code_file, secret_code=0
    begin
      encrypted_core_str = File.open(code_file, 'rb').read
      secrect_codes = nil
      case secret_code
      when 0
        secret_file = Rails.root + "tmp/tk_secret.txt"
      when 1
        secret_file = Rails.root + "tmp/tk1_secret.txt"
      else
        secret_file = Rails.root + "tmp/tk_secret.txt"
      end
      if File.exists?(secret_file)
        secrect_codes = File.open(secret_file, 'rb').read
        secrect_codes.strip!
        secrect_codes.chomp!
      end
      return (secrect_codes.blank?? encrypted_core_str.decrypt : encrypted_core_str.decrypt(secrect_codes))
    rescue Exception => ex
      #
    end
  end
end

# module ReportPlusModule
#   module ReportPlus
#     module_function

#   end
# end

# target_klass_arr = %W{
#   mongodb_report_constructor
#   mongodb_report_pupil_generator
#   mongodb_report_group_generator
# }
# target_klass_arr.each{|klass|
#   code_file = Rails.root + "config/initializers/patches/#{klass}_patch.txt"
#   secret_file = Rails.root + "tmp/tk_secret.txt"
#   klass_arr = klass.split("mongodb_")
#   klass_prefix = (klass_arr.size > 1 )? "Mongodb::" : ""
#   klass_str = klass_prefix + klass_arr.map{|item| item.camelize}.join("")
#   klass_str.constantize.class_eval do
#     begin
#       eval(TkEncryption::codes_str_decryption(code_file, secret_file))
#     rescue Exception => ex
#       #   
#     end
#   end
# }

module Doorkeeper
  class AccessGrant
    belongs_to :user, foreign_key: "resource_owner_id", class_name: "User"
  end

  class AccessToken
    belongs_to :user, foreign_key: "resource_owner_id", class_name: "User"
  end

  class Application
    belongs_to :user, foreign_key: "resource_owner_id", class_name: "User"
  end
end
