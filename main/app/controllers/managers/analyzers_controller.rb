# -*- coding: UTF-8 -*-
#
class Managers::AnalyzersController < ApplicationController

  layout 'manager_crud'

  respond_to :json, :html

  before_action :get_user, only: [:edit, :update]

  def index
    @analyzers = Analyzer.get_list params
    respond_with({rows: @analyzers, total: @analyzers.total_count}) 
  end

  # 创建分析员
  def create
    new_user = User.new

    status = 403
    data = {:status => 403 }

    begin
      new_user.save_user(Common::Role::Analyzer, user_params)
      if new_user.errors && new_user.errors.messages.blank?
        status = 200
        data = {:status => 200, :message => "200" }
      else
        status = 500
        data = {:status => 500, :message => format_error(new_user) }
      end
    rescue Exception => ex
      status = 500
      data = {:status => 500, :message => ex.message}
    end

    render common_json_response(status, data)
  end

  def update
    status = 403
    data = {:status => 403 }

    begin
      @user.update_user(Common::Role::Analyzer, user_params)
      if @user.errors && @user.errors.messages.blank?
        status = 200
        data = {:status => 200, :message => "200" }
      else
        status = 500
        data = {:status => 500, :message => format_error(@user) }
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

    begin
      target_analyzers = Analyzer.where(:uid=> params[:id])
      target_analyzers.each{|ana| ana.destroy_analyzer}
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
    #@user = User.where("name = ? ", params[:user_name]).first
    params.permit(:id)
    analyzer = Analyzer.find(params[:id])
    @user = analyzer.user
    #return @analyzer.nil?? nil : @user.analyzer
  end

  def user_params
    params.permit(
      :user_name,
      :password,
      :password_confirmation,
      :name,
      # :province_rid,
      # :city_rid,
      # :district_rid, 
      :tenant_uids, 
      :subject, 
      :qq, 
      :phone,
      :email)
  end

end
