class Managers::RolesController < ApplicationController
  respond_to :json, :html

  layout 'manager_crud', except: [:show]

  before_action :set_role, only: [:show, :edit, :update, :permission_management,:combine_permissions,:combine_api_permissions]
    # skip_before_action :authenticate_person!
    # before_action :authenticate_manager

  def index
    #@data = {name: '角色', path: '/managers/roles'}
    @roles = Role.page(params[:page]).per(params[:rows])
    respond_with({rows: @roles, total: @roles.total_count}) 
  end

  def create
    @role = Role.new(role_params)
    render json: response_json_by_obj(@role.save, @role)
  end

  def show
    # @permissions = @role.roles_permissions_links.includes(:permission)
    render layout: 'manager'
  end

  def update
    render json: response_json_by_obj(@role.update(role_params), @role)
  end

  def destroy_all
    Role.destroy(params[:id])
    respond_with(@role)
  end

  def permission_management
    render layout: 'manager'
  end

  def combine_permissions
    p permission_params[:permission_ids]
    if @role && @role.combine_permissions(permission_params[:permission_ids])
      render status: 200, json: { :message => "success!" }.to_json 
    else
      render status: 500, json: { :message => "failed!" }.to_json
    end
  end

  def combine_api_permissions
    if @role && @role.combine_api_permissions(permission_params[:permission_ids])
      render status: 200, json: { :message => "success!" }.to_json 
    else
      render status: 500, json: { :message => "failed!" }.to_json
    end
  end

  private

    def set_role
      @role = Role.where(id:params[:id]).first
    end

    def role_params
      params.permit(:name, :desc)
    end

    def permission_params
      params.permit(:permission_ids =>[])
    end
end
