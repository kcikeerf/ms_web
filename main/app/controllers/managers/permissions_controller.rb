class Managers::PermissionsController < ApplicationController

  respond_to :json, :html

  layout 'manager_crud'

  before_action :set_permission, only: [:edit, :update]
  before_action :set_role, only: [:list]
    # skip_before_action :authenticate_person!
    # before_action :authenticate_manager

  def index
    @permissions = Permission.page(params[:page]).per(params[:rows])
    respond_with({rows: @permissions, total: @permissions.total_count}) 
  end

  def create
    @permission = Permission.new(permission_params)
    render json: response_json_by_obj(@permission.save, @permission)
  end

  def update
    @permission.update(permission_params)
    render json: response_json_by_obj(@permission.update(permission_params), @permission)
  end

  def destroy_all
    Permission.destroy(params[:id])
    respond_with(@permission)
  end

  def list
    permissions_data = @role.blank?? Permission : @role.permissions
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
      @permission = Permission.where(id: params[:id]).first
    end

    def permission_params
      params.permit(:id, :name, :subject_class, :operation, :description, :role_id)
    end
end
