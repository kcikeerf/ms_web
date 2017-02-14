# -*- coding: UTF-8 -*-

class Managers::AreaAdministratorsController < ApplicationController
  layout 'manager_crud'

  respond_to :json, :html, :xml

  before_action :get_user, only: [:edit, :update]

  # 列表
  def index
    @area_admins = AreaAdministrator.get_list(params)
    respond_with({rows: @area_admins, total: @area_admins.total_count})
  end

  # 创建
  def create
    new_user = User.new

    status = 403
    data = {:status => 403 }

    begin
      new_user.save_user(Common::Role::AreaAdministrator, user_params)
      if new_user.errors && new_user.errors.messages.blank?
        status = 200
        data = {:status => 200, :message => "200" }
      else
        raise format_error(new_user)
      end
    rescue Exception => ex
      new_user.destroy! if new_user.id
      status = 500
      data = {:status => 500, :message => ex.message}
    end

    render common_json_response(status, data)
  end

  def update
    status = 403
    data = {:status => 403 }

    begin
      @user.update_user(Common::Role::AreaAdministrator, user_params)
      if @user.errors && @user.errors.messages.blank?
        status = 200
        data = {:status => 200, :message => "200" }
      else
        raise format_error(@user)
      end
    rescue Exception => ex
      status = 500
      data = {:status => 500, :message => ex.message}
    end

    render common_json_response(status, data)
  end

  # 删除
  def destroy_all
    params.permit(:id)

    status = 403
    data = {:status => 403 }

    begin
      target_area_administrators = AreaAdministrator.where(:uid=> params[:id])
      target_area_administrators.each{|u| u.destroy_obj}
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
    proj_admin = AreaAdministrator.find(params[:id])
    @user = proj_admin.user
  end

  def user_params
    params.permit(
      :user_name,
      :password,
      :password_confirmation,
      :name,
      :province_rid,
      :city_rid,
      :district_rid, 
      :subject, 
      :qq, 
      :phone,
      :email)
  end
end
