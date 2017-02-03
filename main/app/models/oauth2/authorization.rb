# -*- coding: UTF-8 -*-

class Oauth2::Authorization
  include Mongoid::Document
  include Mongoid::Timestamps

  field :client_id, type: String
  field :user_id, type: String
  field :redirect_uri, type: String
  field :code, type: String
  field :scope, type: Array
  # field :blocked, type: Boolean, default: true
  field :expired_at, type: Time

  index({client_id: 1, redirect_uri:1, code: 1}, {unique: true, background: true})

  before_create :set_expired_at, :random_code

  # 验证code
  # [Return]
  #   0: available code
  #   -1: code expired
  #
  def validate_code
    if expired?
      self.destroy
      return -1
    else
      return 0
    end
  end

  def expired?
    self.expired_at < Time.now
  end

  private

    def set_expired_at
      self.expired_at = Time.now + Common::AuthConfig::CodeExpiresIn
    end

    def random_code
      self.code = loop do 
        code = Common::AuthConfig::random_codes(Common::AuthConfig::CodeLength)
        old_codes = self.class.where(client_id: self.client_id, redirect_uri: self.redirect_uri, code: code)
        break code if old_codes.blank? 
        old_codes.each{|item| item.validate_code }
      end
    end

end
