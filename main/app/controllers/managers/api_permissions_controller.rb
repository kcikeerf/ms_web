class Managers::ApiPermissionsController < ApplicationController
  respond_to :json, :html

  layout 'manager_crud'

  before_action :set_role
  before_action :set_permission, only: [:edit, :update]
    # skip_before_action :authenticate_person!
    # before_action :authenticate_manager

  def index
    #@data = {name: '权限', path: '/managers/permissions'}
    @permissions = ApiPermission.page(params[:page]).per(params[:rows])
    respond_with({rows: @permissions, total: @permissions.total_count}) 
  end

  def create
    @permission = ApiPermission.new(permission_params)
    render json: response_json_by_obj(@permission.save, @permission)
  end

  def update
    @permission.update(permission_params)
    render json: response_json_by_obj(@permission.update(permission_params), @permission)
  end

  def destroy_all
    ApiPermission.destroy(params[:id])
    respond_with(@permission)
  end

  def list
    permissions_data = @role.blank?? ApiPermission : @role.api_permissions
    result = permissions_data.select(:id,:name).map{|item|
      {
        :id => item.id,
        :name => item.name
      }
    }
    render json: result.to_json
  end

  private

    def set_role
      @role = Role.where(id: params[:role_id]).first
    end

    def set_permission
      @permission = ApiPermission.find(params[:id])
    end

    def permission_params
      params.permit(:authenticity_token, :id, :name, :method, :path, :description, :role_id)
    end
end
