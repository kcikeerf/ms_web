class UserLink < ActiveRecord::Base
  belongs_to :parent,:class_name=>"User", :foreign_key=>"parent_id"
  belongs_to :child,:class_name=>"User", :foreign_key=>"child_id"
end
