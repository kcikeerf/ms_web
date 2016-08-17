# -*- coding: UTF-8 -*-
#

class Managers::TeachersController < ApplicationController
  layout 'manager_crud'

  respond_to :json, :html

  before_action :get_user, only: [:edit, :update]

  def index
    @data = {name: I18n.t("dict.teacher"), path: '/managers/teachers'}
    @teachers = Teacher.get_list params

    # 学科列表
    @subject_list = Common::Subject::List.map{|k,v| OpenStruct.new({:key=>k, :value=>v})}

    # 班级列表
    @class_room_list = Common::Klass::List.map{|k,v| OpenStruct.new({:key=>k, :value=>v})}

    # tenant用地区信息
    country_rid = Common::Area::CountryRids["zhong_guo"]
    country = Area.where("rid = '#{country_rid}'").first
    @province = country.children_h.map{|a| OpenStruct.new({:rid=>a[:rid], :name_cn=>a[:name_cn]})}
    @city = Area.default_option.map{|a| OpenStruct.new({:rid=>a[:rid], :name_cn=>a[:name_cn]})}
    @district = Area.default_option.map{|a| OpenStruct.new({:rid=>a[:rid], :name_cn=>a[:name_cn]})}

    respond_with({rows: @teachers, total: @teachers.total_count}) 
  end

#   # 创建教师
#   def create
#     new_user = User.new

#     status = 403
#     data = {:status => 403 }

#     begin
#       new_user.save_user(Common::Role::Analyzer, user_params)
# #      result_flag = new_user.id.nil?? false : (new_user.analyzer.nil?? false : true)
#       status = 200
#       data = {:status => 200 }
#     rescue Exception => ex
#       status = 500
#       data = {:status => 500, :message => ex.message}
#     end

#     render common_json_response(status, data)
#   end

  def update
  	#render json: response_json_by_obj(@user.update_user(Common::Role::Analyzer, user_params), @user)

    status = 403
    data = {:status => 403 }

    begin
      @user.update_user(Common::Role::Teacher, user_params)
#      result_flag = new_user.id.nil?? false : (new_user.analyzer.nil?? false : true)
      status = 200
      data = {:status => 200, :message => "200" }
    rescue Exception => ex
      status = 500
      data = {:status => 500, :message => ex.backtrace}
    end

    render common_json_response(status, data)
  end

  # 删除分析员
  def destroy_all
    params.permit(:id)

    status = 403
    data = {:status => 403 }

    begin
      target_teachers = Teacher.where(:uid=> params[:id])
      target_teachers.each{|ana| ana.destroy_teacher}
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
    teacher = Teacher.find(params[:id])
    @user = teacher.user
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
      # :tenant_uid, 
      :subject, 
      :qq, 
      :phone,
      :email)
  end
end
