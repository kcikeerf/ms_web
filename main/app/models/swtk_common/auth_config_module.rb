# -*- coding: UTF-8 -*-

module AuthConfigModule
  module AuthConfig
    # 过期时间限制
    CodeExpiresIn = 10.minutes.to_i
    TokenExpiresIn = 2.hours.to_i
    RefreshTokenExpiresIn = 1.month.to_i
    # 乱码长度定义
    CodeLength =  10
    TokenLength = 64
    # 分隔符定义
    ScopeSeparator = ","
  end
end