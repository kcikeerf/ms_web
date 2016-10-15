# -*- coding: UTF-8 -*-
#

class Managers::ProjectAdministratorsController < ApplicationController
  layout 'manager_crud'

  respond_to :json, :html

  before_action :get_user, only: [:edit, :update]

  def index
    # @proj_admins = ProjectAdministrator.get_list params
    # respond_with({rows: @proj_admins, total: @proj_admins.total_count}) 
    respond_with({rows: [], total: 0}) 
  end

  # 创建分析员
  def create
    p ">>>>>>>"
    p params[:tenant_uid]
    # new_user = User.new

    status = 403
    data = {:status => 403 }

#     begin
#       new_user.save_user(Common::Role::ProjectAdministrator, user_params)
# #      result_flag = new_user.id.nil?? false : (new_user.analyzer.nil?? false : true)
#       status = 200
#       data = {:status => 200 }
#     rescue Exception => ex
#       status = 500
#       data = {:status => 500, :message => ex.message}
#     end

    render common_json_response(status, data)
  end

  def update
  	#render json: response_json_by_obj(@user.update_user(Common::Role::Analyzer, user_params), @user)

    status = 403
    data = {:status => 403 }

#     begin
#       @user.update_user(Common::Role::Analyzer, user_params)
# #      result_flag = new_user.id.nil?? false : (new_user.analyzer.nil?? false : true)
#       status = 200
#       data = {:status => 200, :message => "200" }
#     rescue Exception => ex
#       status = 500
#       data = {:status => 500, :message => ex.backtrace}
#     end

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
    #@user = User.where("name = ? ", params[:user_name]).first
    # params.permit(:id)
    # analyzer = Analyzer.find(params[:id])
    # @user = analyzer.user
    #return @analyzer.nil?? nil : @user.analyzer
  end

  def user_params
    params.permit(
      :user_name,
      :password,
      :name,
      # :province_rid,
      # :city_rid,
      # :district_rid, 
      :tenant_uid, 
      :subject, 
      :qq, 
      :phone,
      :email)
  end
end
