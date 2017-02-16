class TenantAdministrator < ActiveRecord::Base
  self.primary_key = "uid"

  #concerns
  include TimePatch
  include InitUid

  belongs_to :tenant, foreign_key: "tenant_uid"
  belongs_to :user, foreign_key: "user_id"

  def self.get_list params
    params[:page] = params[:page].blank?? Common::SwtkConstants::DefaultPage : params[:page]
    params[:rows] = params[:rows].blank?? Common::SwtkConstants::DefaultRows : params[:rows]
    result = self.order("dt_update desc").page(params[:page]).per(params[:rows])
    result.each_with_index{|item, index|
      area_h = {
        :province_rid => "",
        :city_rid => "",
        :district_rid => ""
      }
      tenant = item.tenant
      area_h = tenant.area_pcd if tenant
      
      h = {
        :tenant_uids =>  tenant.nil?? "":tenant.uid,
        :tenant_name => tenant.nil?? "":tenant.name_cn,
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

  def save_obj params
    paramsh = {
      :user_id => params[:user_id],
      :name => params[:name], 
      :comment => params[:comment],
      :tenant_uid => params[:tenant_uids]
    }
    update_attributes(paramsh)
    save!
  end

  def self.save_info(options)
    options = options.extract!(:user_id, :name, :tenant_uid, :comment)
  	create(options)
  end

  def destroy_tenant_administrator
    transaction do
      self.user.destroy! if self.user
      self.destroy! if self
    end
  end

end
