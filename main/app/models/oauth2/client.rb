# -*- coding: UTF-8 -*-

class Oauth2::Client
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name
  field :secret_code
  field :machine_code, type: String
  field :scope, type: Array, default: []
  field :blocked, type: Boolean, default: true
  field :expired_at, type: Time

  index({name:1}, {unique: true, background: true})

  before_create :random_secret_code

  def expired?
    self.expired_at < Time.now
  end

  private

    def random_secret_code
      self.secret_code = Common::AuthConfig::random_codes(Common::AuthConfig::SecretCodeLength)
    end
end
