require 'net/ssh'
require 'net/scp'

module WcModule
  module Wc
  	module_function

    WcHost = "10.144.251.201"
    WcUser = "Administrator"
    WcUploadLocation = "docs/"
    WcComponentLocation = "wc/"
    WcComponentTemplate = "#{WcComponentLocation}Templates/swtk.wc"
    WcConvertCommand = "#{WcComponentLocation}WordCleaner7Component.exe" \
      " /t '#{WcComponentTemplate}'" \
      " /f '%{doc_file}'" \
      " /o '%{output_path}'" \
      " /of '%{converted_file_name}' &"


    PrivKey = "
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAoHh6pALw3liFFaa1difmGMSopn1XTeylGOAdrRj5R/5vdCrj
GCfiyvdNCa5pV8gK56Z6as9HdKjPd8UFRgnWWfWjTTv/XixHHtCQlrpok//GurLh
5kxEyq76BfaAzLdoLj4ZKH08CEiR5jVqc0HNIA4nQdJBL36DMeUdTQ9eEKdMgm8k
PHZexpNybmVzZgGSZa3O6llC1thi23bu9YBeCeMCroOwlFtiKOwirs8jMMA3vw85
wZrNWKzeLrJKMiDsfz/XhbbhYAfYdeLX3jp/9qc2/LBZ+pi4mjp4xqyQV0aRZ5Ky
maAyp5LvjVktcz+uDPk91NwIWC1VoKBJU4NVNQIDAQABAoIBAGGEFXMp3logDO/1
WPyujmOqzpouPSm7jzCosSAJtyMK+YvsrAh35JhW5Ffnx1hy1j2jq2zQ/allFH7C
GcxQGhSc81nyBeOioK2XLOaL7RVTL98w6Zpb6soIvyN0gxzkr8i6L+us/xhBkXgG
KeRUrmS2dSDItpg4F13wz3eOySjwqzc1gXT4Thf/LiJ3gJa8FmgKur7k6ZQH0uBc
bHvDqiCyY70L9gmzaT3PzwyHsDowy60BqgGax28gfLVv07DW+BO4w/+m8A5ZSKBj
U/MLL9VQJIPpetdUpgAvt94i+fII/IUemmv/gGjaFeY9UzTpPl0WYLtKDJn+kfmb
ePNGMVkCgYEA09p/pr6aPiChd+7RTZ9UKNu2O0flFzPPVp9zrOpZZoVQ8yBn8708
nmwOZRsj3t5rLfO3ISWNMr7pC/n09SEpy8zoseLAFFOl05cJ08SaWtrL/5B27BNW
U2763E69mQ3Xs5fMnqlX+wxUMqlUl1oovZAKJLiX3QKFDDyF28lUnGMCgYEAwejq
5XegU+prqLLJQu6KDRdWHTVPJ7xGfkczrkoK3VCuQ4xPecyBNY5l6vTAkHSFuXjG
V46P7jqhsJADYID2P2RjuM76CuPToibnzFQmulzlA4kwUo24nBWGFkd/8RIo0uVx
DT/phJKTte79L1OEUn/cQKG0rBLTIrtsmXAdv4cCgYEAz/IAqmMccy8ETvyTZWWm
7hP7Y2TGcWfhdF0+5dOBvSfOtVZxssVk4vudhZCGPRSEj65Raq+5UL4jciX/Uz0i
EXEoVrMDZvBULMRsWPj5qYRqCIh8smyop2yfv+9qGvmDaDzwFCyUt076tl+PMKDG
rIrd6f1m0wDOJ5ygp4OPEZECgYAFjPlMYERCoq86QQPp2pIxFb3tUB1X8dfCvZ8J
Gi19cFXMsTOFNQlt0wmv1Bm/CNbbHE3xK6+LDjqap0Sxen+SCPmhzKrzrNneBmcU
PkRtiUM0+rRbaJskPKl98cYDzJVGlDLMQkwY82kvCAxPUoCzK93OK9LUKiXJFLxj
GAaB+QKBgFkMq6jH1LZalTVoz2D9zBRCnbSP/B+2pN4PBPgCZ2iSiQrbvn/ieDQ/
P0HlwMLoDMKejjFsscyGgx2ElDPcM8EcrW+l8y1JU80vSg4M/lAWLBtdYThhmZ7Q
AgMtgf9KyuLNfye2iWNjxFMneW7Uhhyz0qdRi+T53OXIjryCwlh7
-----END RSA PRIVATE KEY-----
    "

    def convert_doc_through_wc file_path
      return "" if file_path.blank?
      result = ""
      file_path_arr = file_path.split('/')
      file_location = file_path_arr[0..-2].join('/')
      html_file_name = file_path_arr.last.split('.')[0] + '_converted.html' 
      uploadDestination = "#{WcUploadLocation}/#{Time.now.to_snowflake.to_s}/"
      begin
        Net::SSH.start( WcHost, WcUser, :key_data => PrivKey, :keys_only => TRUE) do|ssh|
          #随机生成上传文件夹
          cmd_str = "mkdir #{uploadDestination}"
          ssh.exec! cmd_str

          #文件上传
          ssh.scp.upload!(file_path, uploadDestination)
          
          #doc转换到html
          cmd_h= {
            :doc_file => uploadDestination + file_path_arr.last,
            :output_path => uploadDestination,
            :converted_file_name => html_file_name
          }
          cmd_str = WcConvertCommand % cmd_h
          p cmd_str
          ssh.exec! cmd_str

          #回传html文件
          ssh.scp.download!(uploadDestination + html_file_name, file_location)
          ssh.close
        end
      rescue Exception => ex
        #ex.backtrace
      ensure
        Net::SSH.start( WcHost, WcUser, :key_data => PrivKey, :keys_only => TRUE) do|ssh|
          cmd_str = "rm -rf #{uploadDestination}"
          ssh.exec! cmd_str
        end
      end
      arr = IO.readlines(file_location + "/" + html_file_name)
      result = arr.join('')
      return result
    end
  end
end