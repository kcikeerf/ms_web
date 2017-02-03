# -*- coding: UTF-8 -*-

module AuthConfigModule
  module AuthConfig
    module_function

    # 过期时间限制
    CodeExpiresIn = 10.minutes.to_i
    TokenExpiresIn = 2.hours.to_i
    RefreshTokenExpiresIn = 1.month.to_i
    # 乱码长度定义
    CodeLength =  10
    SecretCodeLength = 32
    TokenLength = 32
    # 分隔符定义
    ScopeSeparator = ","

    def random_codes length
      result = ""
      codes_arr = [*'0'..'9'] + [*'a'..'z'] + [*'A'..'Z']
      length.times{ result << codes_arr.sample}
      result
    end
  end
end