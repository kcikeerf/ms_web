class Tenant < ActiveRecord::Base
  self.primary_key = "uid"

  #concerns
  include TimePatch
  include InitUid

  belongs_to :areas, foreign_key: "area_uid"
  has_many :tenant_administrators, foreign_key: "tenant_uid"
  has_many :analyzers, foreign_key: "tenant_uid"
  has_many :teachers, foreign_key: "tenant_uid"
  has_many :locations, foreign_key: "tenant_uid"
  has_many :project_administrators, through: :project_administrator_tenant_links
  has_many :project_administrator_tenant_links, foreign_key: "tenant_uid"

  ########类方法定义：begin#######
  class << self
    def tenant_type_list
       Common::Tenant::TypeList.map{|k,v| OpenStruct.new({:key=>k, :value=>v})}.sort{|a,b| Common::Locale.mysort(Common::Locale::TenantTypeOrder[a.key],Common::Locale::TenantTypeOrder[b.key]) }
    end

    def get_list params
      params[:page] = params[:page].blank?? Common::SwtkConstants::DefaultPage : params[:page]
      params[:rows] = params[:rows].blank?? Common::SwtkConstants::DefaultRows : params[:rows]
      conditions = []
      [:name_cn, :tenant_type].each{
        |attr| conditions << self.send(:sanitize_sql, ["#{attr} LIKE ?", "%#{params[attr]}%"]) unless params[attr].blank? } 
      conditions = conditions.any? ? conditions.collect { |c| "(#{c})" }.join(' AND ') : nil
      result = self.where(conditions).order("dt_update desc").page(params[:page]).per(params[:rows])
      result.each_with_index{|item, index|
        h = item.area_pcd
        h.merge!(item.attributes)
        h["dt_update"]=h["dt_update"].strftime("%Y-%m-%d %H:%M")
        result[index] = h
      }
      return result
    end

    # def self.get_tenant_uid params
    #   return params[:tenant_uid] if params[:tenant_uid]
    #   return nil if params[:school_number].blank? && params[:school].blank?
    #   paramsh = {
    #     :number => params[:school_number] || "", 
    #     :name => params[:school] || ""
    #   }
    #   targetTenant = Tenant.where(paramsh).first
    #   return targetTenant.nil?? nil : targetTenant.uid
    # end

    def get_tenant_numbers
      return Tenant.all.map{|t| t.number}.uniq.compact
    end

    def generate_tenant_number
      result = ""

      existedTntNumbers = self.get_tenant_numbers
      while existedTntNumbers.include?(result) || result.blank?
        # arr = [*'1'..'9'] + [*'A'..'Z'] + [*'a'..'z']
        Common::Tenant::NumberLength.times{ result << Common::Tenant::NumberRandArr.sample}
      end
      return result
    end
  end
  ########类方法定义：end#######

  def save_tenant params
    tntNumber = self.class.generate_tenant_number
    areaUid,areaRid = Area.get_area_uid_rid params
    paramh = {
      :number => tntNumber,
      :tenant_type => params[:tenant_type] || "",
      :tenant_type_cn => Common::Locale::i18n("tenants.types.#{params[:tenant_type]}"),
      :name => Common::Locale.hanzi2pinyin(params[:name_cn]),
      :name_en => params[:name_en] || "",
      :name_cn => params[:name_cn] || "",
      :name_abbrev => params[:name_abbrev] || "",
      :watchword => params[:watchword] || "",
      :k12_type => params[:k12_type] || "",
      :school_type => params[:school_type] || "",
      :address => params[:address] || "",
      :email =>  params[:email] || "",
      :phone =>  params[:phone] || "",
      :web =>  params[:web] || "",
      :build_at =>  params[:build_at] || "",
      :comment => params[:comment] || "",
      :area_uid => areaUid || "",
      :area_rid => areaRid || ""
    }
    update_attributes(paramh)
    save!
  end

  def update_tenant params
    areaUid, areaRid = Area.get_area_uid_rid params
    paramh = {
      #:number => params[:number],
      :tenant_type => params[:tenant_type] || "",
      :tenant_type_cn => Common::Locale::i18n("tenants.types.#{params[:tenant_type]}"),
      :name => Common::Locale.hanzi2pinyin(params[:name_cn]),
      :name_en => params[:name_en] || "",
      :name_cn => params[:name_cn] || "",
      :name_abbrev => params[:name_abbrev] || "",
      :watchword => params[:watchword] || "",
      :k12_type => params[:k12_type] || "",
      :school_type => params[:school_type] || "",
      :address => params[:address] || "",
      :email =>  params[:email] || "",
      :phone =>  params[:phone] || "",
      :web =>  params[:web] || "",
      :build_at =>  params[:build_at] || "",
      :comment => params[:comment] || "",
      :area_uid => areaUid || "",
      :area_rid => areaRid || ""
    }
    update_attributes(paramh)
    save!
  end

  def papers
    # Mongodb::BankPaperPap.where(:tenant_uid => self.uid).to_a + 
    # Mongodb::BankTestTenantLink.where(:tenant_uid => self.uid).map{|item| item.bank_test.bank_paper_pap}
    tests =self.bank_tests
    pap_ids = tests.map{|t| t.bank_paper_pap.id.to_s if t && t.bank_paper_pap  }.compact
    @papers_filter = { 
      id: {'$in'=>pap_ids} 
    }
    Mongodb::BankPaperPap.where(@papers_filter).order({dt_update: :desc})
  end

  def area
    result = Area.where(:uid=>area_uid).first
    result = result.nil?? OpenStruct.new(Area.default_option[0]):result
    result
  end

  def area_pcd
    result = {
      :province_rid => "",
      :province_name_cn => "",
      :city_rid => "",
      :city_name_cn => "",
      :district_rid => "",
      :district_name_cn => ""
    }
    case area.area_type
    when "country"
      #do nothing
    when "province"
      result[:province_rid] = area.rid
      result[:province_name_cn] = area.name_cn 
    when "city"
      result[:province_rid] = area.parent.rid 
      result[:province_name_cn] = area.parent.name_cn 
      result[:city_rid] = area.rid
      result[:city_name_cn] = area.name_cn
    when "district"
      result[:province_rid] = area.parent.parent.rid 
      result[:province_name_cn] = area.parent.parent.name_cn 
      result[:city_rid] = area.parent.rid
      result[:city_name_cn] = area.parent.name_cn
      result[:district_rid] = area.rid
      result[:district_name_cn] = area.name_cn
    end
    result
  end

  # 获取租户的年级班级列表
  #
  def grades_klasses options={}
    result = []
    target_locations = options[:grade].blank?? locations : locations.by_grade(options[:grade])
    grade = nil
    target_locations.each{|item|
      next unless (!options[:loc_uids].blank? && options[:loc_uids].include?(item.uid))
      if grade && grade[:name] == item.grade
        grade = grade
      else
        grade = {
          :name => item.grade,
          :name_cn => Common::Grade::List[item.grade.to_sym],
          :items => []
        }
        result << grade
      end
      grade[:items] << {
        :location_uid => item.uid,
        :name => item.classroom,
        :name_cn => Common::Klass::List[item.classroom.to_sym]
      }
    }

    # 排序年级
    result = result.sort{|a,b|
      Common::Locale.mysort(Common::Grade::Order[a.grade.nil?? "":a.grade.to_sym],Common::Grade::Order[b.grade.nil?? "":b.grade.to_sym])
    }

    # 排序各年级班级
    result.map{|item|
      item[:items] = item[:items].sort{|a,b| Common::Locale.mysort(Common::Klass::Order[a[:name].nil?? "":a[:name]],Common::Klass::Order[b[:name].nil?? "":b[:name]]) }
      item
    }
  end

  def bank_tests
    _test_ids = Mongodb::BankTestTenantLink.where(tenant_uid: self.uid).distinct(:bank_test_id)
    Mongodb::BankTest.where(id: {"$in" => _test_ids })    
  end

  def union_tests
    _test_ids = Mongodb::UnionTestTenantLink.where(tenant_uid: self.uid).distinct(:union_test_id)
    Mongodb::UnionTest.where(id: {"$in" => _test_ids })
  end

end
