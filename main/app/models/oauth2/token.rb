# -*- coding: UTF-8 -*-

class Oauth2::Token
  include Mongoid::Document
  include Mongoid::Timestamps

  field :client_id
  field :user_id
  field :redirect_uri, type: String
  field :access_token, type: String
  field :scope, type: Array, default: []
  field :refresh_token, type: String
  # field :blocked, type: Boolean, default: true
  field :expired_at, type: Time

  index({token:1}, {unique: true, background: true})
  index({refresh_token:1}, {unique: true, background: true})

  def token_expired?
    self.expired_at < Time.now
  end

  def refresh_token_expired?
    self.dt_created + < Time.now
  end

end
