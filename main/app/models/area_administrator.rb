# -*- coding: UTF-8 -*-

class AreaAdministrator < ActiveRecord::Base
  self.primary_key = "uid"

  #concerns
  include TimePatch
  include InitUid

  belongs_to :user, foreign_key: "user_id"
  belongs_to :area, foreign_key: "area_uid"

  # class method definition begin
  class << self
    def get_list params
      params[:page] = params[:page].blank?? Common::SwtkConstants::DefaultPage : params[:page]
      params[:rows] = params[:rows].blank?? Common::SwtkConstants::DefaultRows : params[:rows]
      result = self.order("dt_update desc").page(params[:page]).per(params[:rows])
      result.each_with_index{|item, index|
      	#获得地区信息
        area_h = {
          :province_rid => "",
          :city_rid => "",
          :district_rid => ""
        }
        target_area = Area.where(rid: item.area_rid).first
        if target_area
          area_h[:province_rid] = target_area.pcd_h[:province][:rid]
          area_h[:city_rid] = target_area.pcd_h[:city][:rid]
          area_h[:district_rid] = target_area.pcd_h[:district][:rid]
        end

        h = {
          :user_name => item.user.nil?? "":item.user.name,
          :qq => item.user.nil?? "":(item.user.qq.blank?? "":item.user.qq),
          :phone => item.user.nil?? "":(item.user.phone.blank?? "":item.user.phone),
          :email => item.user.nil?? "":(item.user.email.blank?? "":item.user.email)
        }
        h.merge!(area_h)
        h.merge!(item.attributes)
        h["dt_update"]=h["dt_update"].strftime("%Y-%m-%d %H:%M")
        result[index] = h
      }
      return result
    end
  end
  # class method definition end

  def save_obj params
    area_ird = params[:province_rid] unless params[:province_rid].blank?
    area_rid = params[:city_rid] unless params[:city_rid].blank?
    area_rid = params[:district_rid] unless params[:district_rid].blank?
    target_area = Area.where(rid: area_rid).first
    paramsh = {
      :user_id => params[:user_id],
      :name => params[:name],
      :area_uid => target_area.uid,
      :area_rid => target_area.rid
    }
    update_attributes(paramsh)
    save!
  end

  def destroy_obj
    transaction do
      self.user.destroy! if self.user
      self.destroy! if self
    end
  end

end
