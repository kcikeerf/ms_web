class  Managers::AreasController < ApplicationController
  layout false

  def get_province
    params.permit!
    country_rid = Common::Area::CountryRids["zhong_guo"]
    @country = Area.where("rid = '#{country_rid}'").first
    render :json => @country.children_h.to_json
  end

  def get_city
  	params.permit!
    province_rid = params[:province_rid]

    result =  Area.default_option

    unless params[:province_rid].blank?
      current_province = Area.where("rid = '#{province_rid}'").first
      result = current_province.children_h if current_province 
    end
    render :json => result.to_json
  end

  def get_district
    params.permit!
    city_rid = params[:city_rid]

    result = Area.default_option

    unless params[:city_rid].blank?
      current_city = Area.where("rid = '#{city_rid}'").first
      result = current_city.children_h if current_city
    end
    render :json => result.to_json
  end

  def get_tenants
    params.permit!

    areas = Area.where("rid LIKE '#{params[:area_rid]}%'")
    tenants = areas.map{|a| a.tenants}.flatten
    render :json => tenants.to_json
  end
end