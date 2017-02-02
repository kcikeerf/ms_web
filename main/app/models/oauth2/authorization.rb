# -*- coding: UTF-8 -*-

class Oauth2::Authorization
  include Mongoid::Document
  include Mongoid::Timestamps

  field :client_id
  field :user_id, type: String
  field :redirect_uri, type: String
  field :code, type: String
  field :scope, type: Array, default: []
  # field :blocked, type: Boolean, default: true
  field :expired_at, type: Time
end
