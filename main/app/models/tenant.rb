class Tenant < ActiveRecord::Base
  self.primary_key = "uid"

  #concerns
  include TimePatch
  include InitUid

  belongs_to :areas, foreign_key: "area_uid"
  has_many :analyzers, foreign_key: "tenant_uid"

  def save_tenant params
    tntNumber = self.class.generate_tenant_number
    areaUid,areaRid = Area.get_area_uid_rid params
  	paramh = {
      :number => tntNumber,
      :tenant_type => params[:tenant_type] || "",
      :tenant_type_cn => I18n.t("tenants.types.#{params[:tenant_type]}"),
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
      :tenant_type_cn => I18n.t("tenants.types.#{params[:tenant_type]}"),
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
    Mongodb::BankPaperPap.where(:tenant_uid => rid).to_a
  end

  def area
    result = Area.where(:uid=>area_uid).first
    result = result.nil?? OpenStruct.new(Area.default_option[0]):result
    result
  end

  def area_pcd
    result = {
      :province_rid => "",
      :city_rid => "",
      :district_rid => ""
    }
    case area.area_type
    when "country"
      #do nothing
    when "province"
      result[:province_rid] = area.rid 
    when "city"
      result[:province_rid] = area.parent.rid 
      result[:city_rid] = area.rid
    when "district"
      result[:province_rid] = area.parent.parent.rid 
      result[:city_rid] = area.parent.rid
      result[:district_rid] = area.rid
    end
    result
  end

  def self.tenant_type_list
     Common::Tenant::TypeList.map{|k,v| OpenStruct.new({:key=>k, :value=>v})}.sort{|a,b| Common::Locale.mysort(Common::Locale::TenantTypeOrder[a.key],Common::Locale::TenantTypeOrder[b.key]) }
  end

  def self.get_list params
    result = self.page(params[:page]).per(params[:rows])
    result.each_with_index{|item, index|
      h = item.area_pcd
      h.merge!(item.attributes)
      h["dt_update"]=h["dt_update"].strftime("%Y-%m-%d %H:%M")
      result[index] = h
    }
    return result
  end

  def self.get_tenant_uid params
    return params[:tenant_uid] if params[:tenant_uid]
    return nil if params[:school_number].blank? && params[:school].blank?
    paramsh = {
      :number => params[:school_number] || "", 
      :name => params[:school] || ""
    }
    targetTenant = Tenant.where(paramsh).first
    return targetTenant.nil?? nil : targetTenant.uid
  end

  def self.get_tenant_numbers
    return Tenant.all.map{|t| t.number}.uniq.compact
  end

  def self.generate_tenant_number
    result = ""

    existedTntNumbers = self.get_tenant_numbers
    while existedTntNumbers.include?(result) || result.blank?
      arr = [*'1'..'9'] + [*'A'..'Z'] + [*'a'..'z']
      Common::School::NumberLength.times{ result << arr.sample}
    end
    return result
  end

end
