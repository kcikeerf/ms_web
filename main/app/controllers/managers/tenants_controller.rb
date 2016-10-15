# -*- coding: UTF-8 -*-
#

class Managers::TenantsController < ApplicationController
  layout 'manager_crud'

  respond_to :json, :html

  before_action :get_tenant, only: [:edit, :update]

  def index
    #@data = {name: 'Tenant', path: '/managers/tenants'}

    # tenant列表数据
    @tenants = Tenant.get_list params 

    # tenant类型数据
    @type_list = Tenant.tenant_type_list
    
    # tenant用地区信息
    country_rid = Common::Area::CountryRids["zhong_guo"]
    country = Area.where("rid = '#{country_rid}'").first
    @province = country.children_h.map{|a| OpenStruct.new({:rid=>a[:rid], :name_cn=>a[:name_cn]})}
    @city = Area.default_option.map{|a| OpenStruct.new({:rid=>a[:rid], :name_cn=>a[:name_cn]})}
    @district = Area.default_option.map{|a| OpenStruct.new({:rid=>a[:rid], :name_cn=>a[:name_cn]})}

    respond_with({rows: @tenants, total: @tenants.total_count}) 
  end

  def create
    @tenant = Tenant.new
  	render json: response_json_by_obj(@tenant.save_tenant(tenant_params), @tenant)
  end

  def update
  	#@tenant.update(tenant_params)
  	render json: response_json_by_obj(@tenant.update_tenant(tenant_params), @tenant)
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
    params.permit(
      :number, 
      :name, 
      :name_cn, 
      :tenant_type, 
      :watchword, 
      :address, 
      :build_at,
      :phone, 
      :email, 
      :web, 
      :comment,
      :province_rid,
      :city_rid,
      :district_rid)
  end
end
