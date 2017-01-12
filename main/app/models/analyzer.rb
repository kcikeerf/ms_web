# -*- coding: UTF-8 -*-

class Analyzer < ActiveRecord::Base
  self.primary_key = "uid"

  #concerns
  include TimePatch
  include InitUid

  belongs_to :user
  belongs_to :tenant, foreign_key: "tenant_uid"
  has_many :score_uploads, foreign_key: "ana_uid"
  has_one :active_create_report_task, ->{ where(type: Task::Type::CreateReport , status: Task::Status::Active)},
          class_name: "TaskList", 
          foreign_key: "ana_uid"
          
  has_one :active_upload_score_task, ->{ where(type: Task::Type::ImportScore , status: Task::Status::Active)},
          class_name: "TaskList", 
          foreign_key: "ana_uid"

  scope :by_tenant, ->(t_uid) { where( tenant_uid: t_uid) if t_uid.present? }
  scope :by_keyword, ->(keyword) { where( "name LIKE '%#{keyword}%'" ) if keyword.present? }

  # class method definition begin
  class << self
    def get_list params
      params[:page] = params[:page].blank?? Common::SwtkConstants::DefaultPage : params[:page]
      params[:rows] = params[:rows].blank?? Common::SwtkConstants::DefaultRows : params[:rows]
      result = self.order("dt_update desc").page(params[:page]).per(params[:rows])
      result.each_with_index{|item, index|
        area_h = {
          :province_rid => "",
          :city_rid => "",
          :district_rid => ""
        }
        area_h = item.tenant.area_pcd if item.tenant
        h = {
          :tenant_uids => item.tenant_uid,
          :tenant_name => item.tenant.nil?? "":item.tenant.name_cn,
          :user_name => item.user.nil?? "":item.user.name,
          :subject_cn => Common::Locale::i18n("dict.#{item.subject}"),
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
       
    def save_info(options)
      options = options.extract!(:user_id, :name, :subject, :tenant_uid)
      create(options)
    end
  end
  # class method definition end

  def save_obj params
    paramsh = {
      :user_id => params[:user_id],
      :name => params[:name], 
      :subject => params[:subject],
      :tenant_uid => params[:tenant_uids]
    }
    update_attributes(paramsh)
    save!
  end

  def destroy_analyzer
    transaction do
      self.user.destroy! if self.user
      self.destroy! if self
    end
  end

  def papers
    Mongodb::BankPaperPap.by_user(self.user.id)
  end
end
