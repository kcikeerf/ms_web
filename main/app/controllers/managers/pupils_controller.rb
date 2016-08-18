# -*- coding: UTF-8 -*-
#

class Managers::PupilsController < ApplicationController
  layout 'manager_crud'

  respond_to :json, :html

  before_action :get_user, only: [:edit, :update]

  def index
    @data = {name: I18n.t("dict.pupil"), path: '/managers/pupils'}
    @pupils = Pupil.get_list params

    # 性别列表
    @sex_list = Common::Locale::SexList.map{|k,v| OpenStruct.new({:key=>k, :value=>v})}
    
    # 年级列表
    @grade_list = Common::Grade::List.map{|k,v| OpenStruct.new({:key=>k, :value=>v})}

    # 班级列表
    @class_room_list = Common::Klass::List.map{|k,v| OpenStruct.new({:key=>k, :value=>v})}

    # tenant用地区信息
    country_rid = Common::Area::CountryRids["zhong_guo"]
    country = Area.where("rid = '#{country_rid}'").first
    @province = country.children_h.map{|a| OpenStruct.new({:rid=>a[:rid], :name_cn=>a[:name_cn]})}
    @city = Area.default_option.map{|a| OpenStruct.new({:rid=>a[:rid], :name_cn=>a[:name_cn]})}
    @district = Area.default_option.map{|a| OpenStruct.new({:rid=>a[:rid], :name_cn=>a[:name_cn]})}

    respond_with({rows: @pupils, total: @pupils.total_count}) 
  end

#   # 创建学生
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

  # 更新学生
  def update
  	#render json: response_json_by_obj(@user.update_user(Common::Role::Analyzer, user_params), @user)

    status = 403
    data = {:status => 403 }

    begin
      @user.update_user(Common::Role::Pupil, user_params)
#      result_flag = new_user.id.nil?? false : (new_user.analyzer.nil?? false : true)
      status = 200
      data = {:status => 200, :message => "200" }
    rescue Exception => ex
      status = 500
      data = {:status => 500, :message => ex.backtrace}
    end

    render common_json_response(status, data)
  end

  # 删除学生
  def destroy_all
    params.permit(:id)

    status = 403
    data = {:status => 403 }

    begin
      target_pupils = Pupil.where(:uid=> params[:id])
      target_pupils.each{|pup| pup.destroy_pupil}
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
    pupil = Pupil.find(params[:id])
    @user = pupil.user
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
      :stu_number,
      :sex,
      :grade,
      :classroom, 
      :qq, 
      :phone,
      :email)
  end
end
