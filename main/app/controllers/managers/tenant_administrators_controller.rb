# -*- coding: UTF-8 -*-
#

class Managers::TenantAdministratorsController < ApplicationController
  layout 'manager_crud'

  respond_to :json, :html

  before_action :get_user, only: [:edit, :update]

  def index
    @tenant_administrators = TenantAdministrator.get_list params
    respond_with({rows: @tenant_administrators, total: @tenant_administrators.total_count}) 
  end

  # 创建Tenant管理员
  def create
    new_user = User.new

    status = 403
    data = {:status => 403 }

    begin
      new_user.save_user(Common::Role::TenantAdministrator, user_params)
#      result_flag = new_user.id.nil?? false : (new_user.analyzer.nil?? false : true)
      status = 200
      data = {:status => 200 }
    rescue Exception => ex
      status = 500
      data = {:status => 500, :message => ex.message}
    end

    render common_json_response(status, data)
  end

  # 更新Tenant管理员
  def update
    status = 403
    data = {:status => 403 }

    begin
      @user.update_user(Common::Role::TenantAdministrator, user_params)
      status = 200
      data = {:status => 200, :message => "200" }
    rescue Exception => ex
      status = 500
      data = {:status => 500, :message => ex.message}
    end

    render common_json_response(status, data)
  end

  # 删除Tenant管理员
  def destroy_all
    params.permit(:id)

    status = 403
    data = {:status => 403 }

    begin
      target_tenant_administrators = TenantAdministrator.where(:uid=> params[:id])
      target_tenant_administrators.each{|tadmin| tadmin.destroy_tenant_administrator}
      status = 200
      data = {:status => "200"}
    rescue Exception => ex
      status = 500
      data = {:status => 500, :message => ex.message}
    end

  	render common_json_response(status, data)
  end

  private
  def get_user
    params.permit(:id)
    tenant_administrator = TenantAdministrator.find(params[:id])
    @user = tenant_administrator.user
  end

  def user_params
    params.permit(
      :user_name,
      :password,
      :name,
      # :province_rid,
      # :city_rid,
      # :district_rid, 
      # :tenant_uid, 
      :tenant_uids,
      :qq, 
      :phone,
      :email)
  end
end
