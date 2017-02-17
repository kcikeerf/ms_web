class Skope < ActiveRecord::Base
  has_many :user_skope_links, foreign_key: "skope_id"
  has_many :users, through: :user_skope_links
  has_many :skope_rules, foreign_key: "skope_id"
end
