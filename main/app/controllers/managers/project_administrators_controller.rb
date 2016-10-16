# -*- coding: UTF-8 -*-
#

class Managers::ProjectAdministratorsController < ApplicationController
  layout 'manager_crud'

  respond_to :json, :html, :xml

  before_action :get_user, only: [:edit, :update]

  # 列表
  def index
    @proj_admins = ProjectAdministrator.get_list(params)
    respond_with({rows: @proj_admins, total: @proj_admins.total_count})
  end

  # 创建
  def create
    new_user = User.new

    status = 403
    data = {:status => 403 }

    begin
      new_user.save_user(Common::Role::ProjectAdministrator, user_params)
      if new_user.errors && new_user.errors.messages.blank?
        status = 200
        data = {:status => 200, :message => "200" }
      else
        raise format_error(new_user)
      end
    rescue Exception => ex
      new_user.destroy!
      status = 500
      data = {:status => 500, :message => ex.message}
    end

    render common_json_response(status, data)
  end

  def update
    status = 403
    data = {:status => 403 }

    begin
      @user.update_user(Common::Role::ProjectAdministrator, user_params)
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

  # 删除分析员
  def destroy_all
    params.permit(:id)

    status = 403
    data = {:status => 403 }

    # begin
    #   target_analyzers = Analyzer.where(:uid=> params[:id])
    #   target_analyzers.each{|ana| ana.destroy_analyzer}
    #   status = 200
    #   data = {:status => "200"}
    # rescue Exception => ex
    #   status = 500
    #   data = {:status => 500, :message => ex.message}
    # end

  	render common_json_response(status, data)
  end

  private
  def get_user
    params.permit(:id)
    proj_admin = ProjectAdministrator.find(params[:id])
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
      :email,
      :tenant_uid => [])
  end
end
