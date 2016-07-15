class Permission < ActiveRecord::Base
  #has_many :roles, foreign_key: "permission_id", through: :roles_permissions_links 
  has_many :roles_permissions_links, dependent: :destroy
  has_many :roles, :through => :roles_permissions_links 

  validates :subject_class, :action, presence: true

  def permission_name
  	"#{name}--#{subject_class}--#{action}"
  end
end
