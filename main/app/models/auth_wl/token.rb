# -*- coding: UTF-8 -*-

class AuthWl::Token
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id
  field :access_token, type: String
  field :scope, type: Array
  field :refresh_token, type: String
  field :expired_at, type: Time

  index({access_token: 1}, {unique: true, background: true})
  index({user_id: 1, refresh_token: 1}, {unique: true, background: true})

  before_create :random_refresh_token
  before_save :set_expired_at, :random_access_token

  ########类方法定义：begin#######
  class << self
    def get_token_obj user_id
      target_token = AuthWl::Token.where(user_id: user_id).first
      if target_token.blank? || [-1].include?(target_token.validate_token) 
        target_token = AuthWl::Token.new(user_id: user_id)
        target_token.save
      end
      target_token
    end
  end
  ########类方法定义：end#######

  # 验证token
  # [Return]
  #   0: available access token 
  #   1: access token expired
  #   2: refresh token expired 
  #
  def validate_token
    return 0 if !access_token_expired? && !refresh_token_expired?
    return 1 if access_token_expired? && !refresh_token_expired?
    if access_token_expired? && refresh_token_expired?
      self.destroy
      return -1
    end
  end

  def access_token_expired?
    self.expired_at < Time.now
  end

  def refresh_token_expired?
    ( self.created_at.strftime("%s").to_i - Time.now.strftime("%s").to_i ) > Common::AuthConfig::RefreshTokenExpiresIn
  end

  private

    def set_expired_at
      self.expired_at = Time.now + Common::AuthConfig::TokenExpiresIn
    end

    def random_access_token
      self.access_token = loop do 
        token = Common::AuthConfig::random_codes(Common::AuthConfig::TokenLength)
        old_tokens = self.class.where(access_token: token)
        break token if old_tokens.blank? 
        old_tokens.each{|item| item.validate_token }
      end
    end

    def random_refresh_token
      self.refresh_token = loop do 
        token = Common::AuthConfig::random_codes(Common::AuthConfig::TokenLength)
        old_tokens = self.class.where(user_id: self.user_id, refresh_token: token)
        break token if old_tokens.blank? 
        old_tokens.each{|item| item.validate_token }
      end
    end
end
