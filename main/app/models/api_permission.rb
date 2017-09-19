class ApiPermission < ActiveRecord::Base
  has_many :roles_api_permissions_links, dependent: :destroy
  has_many :roles, :through => :roles_api_permissions_links , foreign_key: "api_permission_id"

  class << self
    def get_list params
      params[:page] = params[:page].blank?? Common::SwtkConstants::DefaultPage : params[:page]
      params[:rows] = params[:rows].blank?? Common::SwtkConstants::DefaultRows : params[:rows]
      conditions = []
      conditions << self.send(:sanitize_sql, ["name LIKE ?", "%#{params[:name]}%"]) unless params[:name].blank?
      conditions << self.send(:sanitize_sql, ["method LIKE ?", "%#{params[:method]}%"]) unless params[:method].blank?
      conditions << self.send(:sanitize_sql, ["path LIKE ?", "%#{params[:path]}%"]) unless params[:path].blank?
      conditions = conditions.any? ? conditions.collect { |c| "(#{c})" }.join(' AND ') : nil
      result = self.where(conditions).order("updated_at desc").page(params[:page]).per(params[:rows])
      result.each_with_index{|item, index|
        h = {
          :id => item.id,
          :name => item.name,
          :method => item.method,
          :path => item.path,
          :description => item.description,
          :roles => item.roles.pluck(:name),
          :updated_at => item.updated_at.strftime("%Y-%m-%d %H:%M")
        }
        result[index] = h
      }
      return result
    end

    def create_ins(api_permission_params,roles)
      ApiPermission.transaction do
        api_permission = ApiPermission.new(api_permission_params)
        api_permission.save
        api_permission.roles << roles
        roles.each{|role| role.delete_role_auth_redis }
      end
    end
  end

  def update_ins(api_permission_params,roles)
    ApiPermission.transaction do
      delete_roles = self.roles - roles
      add_roles = roles - self.roles
      self.update(api_permission_params)
      self.roles.delete(delete_roles)
      delete_roles.each{|role| role.delete_role_auth_redis }
      self.roles << add_roles
      add_roles.each{|role| role.delete_role_auth_redis }
    end
  end

end
