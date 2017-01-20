# -*- coding: UTF-8 -*-

class Oauth::Client
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name
  field :secret_code
  field :machine_code, type: String
  field :scope, type: Array, default: []
  field :blocked, type: Boolean, default: true
  field :expired_at, type: Time

end
