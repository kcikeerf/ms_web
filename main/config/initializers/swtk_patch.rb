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

module ReportPlusModule
  module ReportPlus
    module_function
    begin
      core_file = Rails.root + "config/initializers/report_plus_patch.txt"
      encrypted_core_str = File.open(core_file, 'rb').read
      secret_file = Rails.root + "tmp/tk_secret.txt"
      secrect_codes = nil
      if File.exists?(secret_file)
        secrect_codes = File.open(secret_file, 'rb').read
        secrect_codes.strip!
        secrect_codes.chomp!
      end
      eval(secrect_codes.blank?? encrypted_core_str.decrypt : encrypted_core_str.decrypt(secrect_codes))
    rescue Exception => ex
      
    end
  end
end

class Mongodb::ReportConstructor
  begin
    core_file = Rails.root + "config/initializers/report_constructor_patch.txt"
    encrypted_core_str = File.open(core_file, 'rb').read
    secret_file = Rails.root + "tmp/tk_secret.txt"
    secrect_codes = nil
    if File.exists?(secret_file)
      secrect_codes = File.open(secret_file, 'rb').read
      secrect_codes.strip!
      secrect_codes.chomp!
    end
    class_eval(secrect_codes.blank?? encrypted_core_str.decrypt : encrypted_core_str.decrypt(secrect_codes))
  rescue Exception => ex
    #
  end  
end

class Mongodb::ReportGroupGenerator
  begin
    core_file = Rails.root + "config/initializers/report_group_generator_patch.txt"
    encrypted_core_str = File.open(core_file, 'rb').read
    secret_file = Rails.root + "tmp/tk_secret.txt"
    secrect_codes = nil
    if File.exists?(secret_file)
      secrect_codes = File.open(secret_file, 'rb').read
      secrect_codes.strip!
      secrect_codes.chomp!
    end
    class_eval(secrect_codes.blank?? encrypted_core_str.decrypt : encrypted_core_str.decrypt(secrect_codes))
  rescue Exception => ex
    #
  end  
end

class Mongodb::ReportPupilGenerator
  begin
    core_file = Rails.root + "config/initializers/report_pupil_generator_patch.txt"
    encrypted_core_str = File.open(core_file, 'rb').read
    secret_file = Rails.root + "tmp/tk_secret.txt"
    secrect_codes = nil
    if File.exists?(secret_file)
      secrect_codes = File.open(secret_file, 'rb').read
      secrect_codes.strip!
      secrect_codes.chomp!
    end
    class_eval(secrect_codes.blank?? encrypted_core_str.decrypt : encrypted_core_str.decrypt(secrect_codes))
  rescue Exception => ex
    #
  end  
end
