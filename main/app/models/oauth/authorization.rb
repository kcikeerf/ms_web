# -*- coding: UTF-8 -*-

class Oauth::Authorization
  include Mongoid::Document
  include Mongoid::Timestamps

  field :client_id
  field :redirect_uri, type: String
  field :code, type: String
  field :scope, type: Array, default: []
  field :blocked, type: Boolean, default: true
  field :expired_at, type: Time
end
