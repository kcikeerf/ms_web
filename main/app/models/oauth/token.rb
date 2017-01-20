# -*- coding: UTF-8 -*-

class Oauth::Token
  include Mongoid::Document
  include Mongoid::Timestamps

  field :client_id
  field :redirect_uri, type: String
  field :access_token, type: String
  field :scope, type: Array, default: []
  field :refresh_token, type: String
  field :blocked, type: Boolean, default: true
  field :expired_at, type: Time
end
