# -*- coding: UTF-8 -*-
class Mongodb::RcTestUserHouse
  include Mongoid::Document
  include Mongodb::MongodbPatch

  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  field :test_id, type: String #测试UID
  field :pap_uid, type: String #试卷UID
  field :province, type: String #省
  field :province_id, type: String #省ID
  field :city, type: String #市
  field :city_id, type: String #市ID
  field :district, type: String #区
  field :district_id, type: String #区ID
  field :tenant, type: String #学校
  field :tenant_uid, type: String #学校UID
  field :grade, type: String #年级
  field :grade_uid, type: String #年级UID
  field :classroom, type: String #班级
  field :loc_uid, type: String #班级UID
  field :name, type: String #姓名
  field :pup_uid, type: String #用户ID
  field :gender, type: Integer #性别
  field :stu_number, type: String #学生号

  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  index({_id: 1}, {background: true})

  def save_ins params
    self.test_id = params[:test_id] if params[:test_id].present?
    self.pap_uid = params[:pap_uid] if params[:pap_uid].present?
    self.province = params[:province] if params[:province].present?
    self.province_id = params[:province_id] if params[:province_id].present?
    self.city = params[:city] if params[:city].present?
    self.city_id = params[:city_id] if params[:city_id].present?
    self.district = params[:district] if params[:district].present?
    self.district_id = params[:district_id] if params[:district_id].present?
    self.tenant = params[:tenant] if params[:tenant].present?
    self.tenant_uid = params[:tenant_uid] if params[:tenant_uid].present?
    self.grade = params[:grade] if params[:grade].present?    
    self.grade_uid = params[:grade_uid] if params[:grade_uid].present?    
    self.classroom = params[:klass] if params[:klass].present?    
    self.loc_uid = params[:klass_uid] if params[:klass_uid].present?    
    self.name = params[:name] if params[:name].present?    
    self.pup_uid = params[:id] if params[:id].present?    
    self.gender = params[:gender] if params[:gender].present?    
    self.stu_number = params[:student_number] if params[:student_number].present?
    self.save!  
  end

end