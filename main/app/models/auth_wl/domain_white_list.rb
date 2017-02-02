# -*- coding: UTF-8 -*-

class AuthWl::DomainWhiteList
  include Mongoid::Document
  include Mongoid::Timestamps

  field :domain, type: String
  field :description, type: String

  index({domain: 1}, {unique: true, background: true})
end
