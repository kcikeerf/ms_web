# -*- coding: UTF-8 -*-

class Mongodb::UnionTest
  include Mongoid::Document
  include Mongodb::MongodbPatch
  include SwtkLockPatch

  attr_accessor :current_user_id
  
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  has_many :bank_tests, class_name: "Mongodb::BankTest", dependent: :delete
  has_many :union_test_area_links, class_name: "Mongodb::UnionTestAreaLink", dependent: :delete
  has_many :union_test_tenant_links, class_name: "Mongodb::UnionTestTenantLink", dependent: :delete
  has_many :union_test_location_links, class_name: "Mongodb::UnionTestLocationLink", dependent: :delete
  has_many :union_test_user_links, class_name: "Mongodb::UnionestUserLink", dependent: :delete
  has_many :union_test_user_links, class_name: "Mongodb::UnionTestUserLink", dependent: :delete
  has_many :bank_paper_paps, class_name: "Mongodb::BankPaperPap"
  scope :by_grade, ->(grade) { where(grade: grade) if grade.present? }
  scope :by_keyword, ->(keyword) { any_of({heading: /#{keyword}/}, {subheading: /#{keyword}/}) if keyword.present? }

  field :name, type: String
  field :heading, type: String
  field :subheading, type: String
  field :school, type: String
  field :grade, type: String
  field :term, type: String
  field :quiz_type, type: String
  field :start_date, type: DateTime
  field :quiz_date, type: DateTime #默认为截止日期
  field :area_rid, type: String
  field :report_top_group, type: String #取几个联考测试的最低值
  field :ext_data_path, type: String # 外挂码
  field :user_id, type: String
  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  index({_id: 1}, {background: true})

  class << self
    def get_list params
      params[:page] = params[:page].blank?? Common::SwtkConstants::DefaultPage : params[:page]
      params[:rows] = params[:rows].blank?? Common::SwtkConstants::DefaultRows : params[:rows]
      conditions = []
      # conditions << self.send(:sanitize_sql, ["name LIKE ?", "%#{params[:name]}%"]) unless params[:name].blank?
      # conditions << self.send(:sanitize_sql, ["email LIKE ?", "%#{params[:email]}%"]) unless params[:email].blank?
      # conditions = conditions.any? ? conditions.collect { |c| "(#{c})" }.join(' AND ') : nil
      # result = self.where(conditions).order("dt_update desc").page(params[:page]).per(params[:rows])
      result = self.all.page(params[:page]).per(params[:rows])
      result.each_with_index{|item, index|
        h = {
          :id => item.id,
          :name => item.name,
          :heading => item.heading,
          :subheading => item.subheading,
          :school => item.school,
          :grade => item.grade,
          :term => item.term,
          :quiz_type => item.quiz_type.strftime("%Y-%m-%d %H:%M"),
          :quiz_date => item.quiz_date.strftime("%Y-%m-%d %H:%M"),
          :dt_update => item.updated_at.strftime("%Y-%m-%d %H:%M")
        }
        result[index] = h
      }
      return result
    end
  end

  def save_ins params
    target_area_ird = params[:province_rid] if params[:province_rid].present?
    target_area_rid = params[:city_rid] if params[:city_rid].present?
    target_area_rid = params[:district_rid] if params[:district_rid].present?
    
    paramsh = {
      :name => params[:name],
      :school => params[:school],
      :heading => params[:heading],
      :subheading => params[:subheading],
      :grade => params[:grade],
      :term => params[:term],
      :quiz_type => params[:quiz_type],
      :quiz_date => params[:quiz_date],
      :start_date => params[:start_date],
      :user_id => current_user_id
    }
    paramsh.merge!({:area_rid => target_area_rid})
    update_attributes(paramsh)
    
    union_test_tenant_links.destroy_all
    params[:tenants].each {|tenant|
        union_test_tenant_link = Mongodb::UnionTestTenantLink.new(tenant_uid: tenant[1]["tenant_uid"], union_test_id: self._id)
        union_test_tenant_link.save!
    }
  end


  def u_test_info
    {
      :id => self._id.to_s,
      :name => self.name,
      :school => self.school,
      :heading => self.heading,
      :subheading => self.subheading,
      :grade => self.grade,
      :term => self.term,
      :quiz_type => self.quiz_type,
      :quiz_date => self.quiz_date,
      :start_date => self.start_date,
      :tenants => self.tenants.map {|t|
        {      
          :uid => t.uid,
          :name => t.name,
          :name_cn => t.name_cn,
          :area_uid => t.area_uid
        } if t
      },
      :bank_paper_paps => self.bank_paper_paps.map { |t|
        {
          :pap_uid => t._id.to_s,
          :subject => t.subject,
          :subject_cn => I18n.t("dict.#{t.subject}"),
          :paper_status => t.paper_status,
          :status => I18n.t("papers.status.#{t.paper_status}"),
          :quiz_date => t.quiz_date
        } if t
      }
    }
  end

  def area_uids 
    union_test_area_links.map(&:area_uid)
  end

  def areas
    Area.where(uid: area_uids)
  end

  def tenant_uids
    union_test_tenant_links.map(&:tenant_uid)
  end

  def tenants
    Tenant.where(uid: tenant_uids)
  end

  def loc_uids
    union_test_location_links.map(&:loc_uid)
  end

  def locations
    Location.where(uid: loc_uids)
  end

  def user_ids
    union_test_user_links.map(&:user_id)
  end

  def users
    User.where(id: user_ids)
  end

end
