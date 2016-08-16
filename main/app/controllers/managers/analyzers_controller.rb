# -*- coding: UTF-8 -*-
#
class Managers::AnalyzersController < ApplicationController

  layout 'manager_crud'

  respond_to :json, :html

  before_action :get_user, only: [:edit, :update]

  def index
    @data = {name: I18n.t("dict.analyzer"), path: '/managers/analyzers'}
    @analyzers = Analyzer.page(params[:page]).per(params[:rows])

    # 学科列表
    @subject_list = Common::Subject::List.map{|k,v| OpenStruct.new({:key=>k, :value=>v})}

    # tenant用地区信息
    country_rid = Common::Area::CountryRids["zhong_guo"]
    country = Area.where("rid = '#{country_rid}'").first
    @province = country.children_h.map{|a| OpenStruct.new({:rid=>a[:rid], :name_cn=>a[:name_cn]})}
    @city = Area.default_option.map{|a| OpenStruct.new({:rid=>a[:rid], :name_cn=>a[:name_cn]})}
    @district = Area.default_option.map{|a| OpenStruct.new({:rid=>a[:rid], :name_cn=>a[:name_cn]})}

    respond_with({rows: @analyzers, total: @analyzers.total_count}) 
  end

  def create
  	render json: response_json_by_obj(User.add_user(user_params), @user)
  end

  def update
  	@user.update(user_params)
  	render json: response_json_by_obj(@user.update(user_params), @user)
  end

  def destroy_all
  	User.destroy(params[:id])
  	respond_with(@user)
  end

  private
  def get_user
    @user = user.where("uid = ? ", params[:id]).first
  end

  def user_params
    params.permit(
      :user_name,
      :name,
      :province_rid,
      :city_rid,
      :district_rid, 
      :school, 
      :subject, 
      :qq, 
      :phone,
      :email)
  end

end
