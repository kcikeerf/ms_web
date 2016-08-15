class Managers::TenantsController < ApplicationController
  layout 'manager_crud'

  respond_to :json, :html

  before_action :get_tenant, only: [:edit, :update]

  def index
    @data = {name: 'Tenant(学校)', path: '/managers/tenants'}
    @tenants = Tenant.page(params[:page]).per(params[:rows])
    respond_with({rows: @tenants, total: @tenants.total_count}) 
  end

  def create
  	render json: response_json_by_obj(Tenant.save_tenant(tenant_params), @tenant)
  end

  def update
  	@tenant.update(tenant_params)
  	render json: response_json_by_obj(@tenant.update(tenant_params), @tenant)
  end

  def destroy_all
  	Tenant.destroy(params[:id])
  	respond_with(@tenant)
  end

  private
  def get_tenant
    @tenant = Tenant.where("uid = ? ", params[:id]).first
  end

  def tenant_params
    params.permit(:name, :school_type, :moto, :address, :build_at,:phone, :email, :web, :comment)
  end
end
