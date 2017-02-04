class Role < ActiveRecord::Base
  has_many :users, foreign_key: "role_id"
  #has_many :permissions, foreign_key: "role_id", through: :roles_permissions_links
  has_many :roles_permissions_links, dependent: :destroy
  has_many :permissions, :through => :roles_permissions_links, foreign_key: "role_id"

  has_many :roles_api_permissions_links, dependent: :destroy
  has_many :api_permissions, :through => :roles_api_permissions_links, foreign_key: "role_id"

  accepts_nested_attributes_for :permissions

  validates :name, presence: true


  def self.get_role_id(name)
  	find_by(name: name).try(:id) || 0
  end

  def combine_permissions permission_ids
    begin
      permission_ids.reject!(&:empty?)
      roles_permissions_links.delete_all
      roles_permissions_links.create(permission_ids.map{|id| {:permission_id => id}})
      return true
    rescue Exception => ex
      p ex.message
      p ex.backtrace
      return false
    end
  end

  def combine_api_permissions api_permission_ids
    begin
      api_permission_ids.reject!(&:empty?)
      roles_api_permissions_links.delete_all
      roles_api_permissions_links.create(api_permission_ids.map{|id| {:api_permission_id => id}})
      return true
    rescue Exception => ex
      return false
    end    
  end
end
