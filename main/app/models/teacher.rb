class Teacher < ActiveRecord::Base
  self.primary_key = "uid"

  #concerns
  include TimePatch
  include InitUid

  belongs_to :tenant, foreign_key: "tenant_uid"
  belongs_to :user
  has_many :class_teacher_mappings, foreign_key: "tea_uid"

  # has_many :classrooms, foreign_key: 'tea_id'
  scope :by_tenant, ->(t_uid) { where( tenant_uid: t_uid) }
  scope :by_keyword, ->(keyword) { where( "name LIKE '%#{keyword}%'" ) if keyword.present? }
  
  accepts_nested_attributes_for :class_teacher_mappings
  

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

      head_teacher = false
      unless item.locations.empty?
        item.locations.each{|loc|
          if item.is_class_headteacher?(loc.uid)
            head_teacher = true
            break
          else
            next
          end
        }
      end
      h = {
        :tenant_uid =>  tenant.nil?? "":tenant.uid,
        :tenant_name => tenant.nil?? "":tenant.name_cn,
        :user_name => item.user.nil?? "":item.user.name,
        :head_teacher => head_teacher ? I18n.t("common.shi") : I18n.t("common.fou"),
        :subject => item.subject,
        :subject_cn => I18n.t("dict.#{item.subject}"),
        :subject_classrooms => item.subjects_classrooms_mapping.map{|m| "#{m[:subject_cn]},#{m[:grade_cn]}#{m[:classroom_cn]}(#{m[:type]})" }.join("<br>"),
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

  def locations
    result = []
    return result unless self.tenant
    self.class_teacher_mappings.by_tenant(self.tenant_uid).map{|item|
      Location.where(:uid => item.loc_uid).first
    }
  end

  def subjects
    result = []
    return result unless self.tenant
    result = self.class_teacher_mappings.by_tenant(self.tenant_uid).map{|item| 
      item.subject
    }
  end

  def subjects_classrooms_mapping
    result = []
    return result unless self.tenant
    self.class_teacher_mappings.by_tenant(self.tenant_uid).map{|item|
      loc = Location.where(:uid => item.loc_uid).first
      {
        :subject => item.subject,
        :subject_cn => I18n.t("dict.#{item.subject}"),
        :grade => loc.grade,
        :grade_cn => I18n.t("dict.#{loc.grade}"),
        :classroom => loc.classroom,
        :classroom_cn => I18n.t("dict.#{loc.classroom}"),
        :type => item.head_teacher ? I18n.t("teachers.abbrev.head_teacher") : I18n.t("teachers.abbrev.subject")
      }
    }
  end

  def is_class_headteacher?(loc_uid)
    result = false
    return result unless self.tenant
    result = true unless self.class_teacher_mappings.by_tenant(self.tenant_uid).by_head_teacher.blank?
    return result
  end

  def grade
    class_teacher_mappings.first.location.grade
  end

  def pupils
    loc_uids = locations.map{|loc| loc.id}
    Pupil.where(:loc_uid => loc_uids)
  end

  def papers
    pap_uids = Mongodb::BankTeaPap.where(tea_uid: self.uid).map{|item| item.pap_uid}
    Mongodb::BankPaperPap.where(:_id.in =>pap_uids).order({dt_update: :desc})
  end

  def save_obj params
    paramsh = {
      :user_id => params[:user_id],
      :name => params[:name], 
      :subject => params[:subject],
      :tenant_uid => params[:tenant_uid]
    }
    update_attributes(paramsh)
    save!
  end

  def self.save_info(options)
    options = options.extract!(:user_id, :name, :loc_uid, :head_teacher, :subject, :tenant_uid)
    mapping_hash = {}
    mapping_hash[:loc_uid] = options[:loc_uid]
    mapping_hash[:head_teacher] = options.delete(:head_teacher)
    mapping_hash[:subject] = options[:subject]
    mapping_hash[:tenant_uid] = options[:tenant_uid]
    options[:class_teacher_mappings_attributes] = [mapping_hash]
    create(options)
  end

  def destroy_teacher
    transaction do
      self.user.destroy! if self.user
      self.destroy! if self
    end
  end
end
