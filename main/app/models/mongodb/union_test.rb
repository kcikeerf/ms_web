# -*- coding: UTF-8 -*-

class Mongodb::UnionTest
  include Mongoid::Document
  include Mongodb::MongodbPatch
  include SwtkLockPatch

  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  has_many :bank_tests, class_name: "Mongodb::BankTest", dependent: :delete
  has_many :union_test_area_links, class_name: "Mongodb::UnionTestAreaLink", dependent: :delete
  has_many :union_test_tenant_links, class_name: "Mongodb::UnionTestTenantLink", dependent: :delete
  has_many :union_test_location_links, class_name: "Mongodb::UnionTestLocationLink", dependent: :delete
  has_many :union_test_user_links, class_name: "Mongodb::UnionTestUserLink", dependent: :delete

  field :name, type: String
  field :quiz_type, type: String
  field :start_date, type: DateTime
  field :quiz_date, type: DateTime #默认为截止日期
  field :area_rid, type: String
  field :report_top_group, type: String #取几个联考测试的最低值
  field :ext_data_path, type: String # 外挂码
  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  index({_id: 1}, {background: true})

  def save_ins params
    target_area_ird = params[:province_rid] if params[:province_rid].present?
    target_area_rid = params[:city_rid] if params[:city_rid].present?
    target_area_rid = params[:district_rid] if params[:district_rid].present?
    
    paramsh = {
      :name => params[:name],
      :start_date => params[:start_date],
      :quiz_date => params[:quiz_date],
      :quiz_type => params[:quiz_type]
    }
    paramsh.merge!({:area_rid => target_area_rid})
    update_attributes(paramsh)
    
    bank_test_tenant_links.destroy_all
    params[:tenant_uids].each {|tenant|
        bank_test_tenant_link = Mongodb::BankTestTenantLink.new(tenant_uid: tenant, bank_test_id: self._id)
        bank_test_tenant_link.save
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
