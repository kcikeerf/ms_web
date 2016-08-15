class Tenant < ActiveRecord::Base
  self.primary_key = "uid"

  #concerns
  include TimePatch
  include InitUid

  belongs_to :areas, foreign_key: "area_uid"

  def self.save_tenant params
    schNumber = generate_school_number
    areaUid = Area.get_area_uid params
  	paramh = {
      :number => schNumber,
      :name => Common::Locale.hanzi2pinyin(params[:name]),
      :name_en => params[:name_en] || "",
      :name_cn => params[:name_cn] || "",
      :name_abbrev => params[:name_abbrev] || "",
      :moto => params[:moto] || "",
      :k12_type => params[:k12_type] || "",
      :school_type => params[:school_type] || "",
      :address => params[:address] || "",
      :email =>  params[:email] || "",
      :phone =>  params[:phone] || "",
      :web =>  params[:web] || "",
      :build_at =>  params[:build_at] || "",
      :comment => params[:comment] || "",
      :area_uid => areaUid || ""
    }
    new_tenant = self.new(paramh)
    new_tenant.save!
  end

  def papers
    Mongodb::BankPaperPap.where(:tenant_uid => rid).to_a
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

  def self.get_school_numbers
    return Tenant.all.map{|t| t.number}.uniq.compact
  end

  def self.generate_school_number
    result = ""

    existedSchNumbers = self.get_school_numbers
    while existedSchNumbers.include?(result) || result.blank?
      arr = [*'1'..'9'] + [*'A'..'Z'] + [*'a'..'z']
      Common::School::NumberLength.times{ result << arr.sample}
    end
    return result
  end

end
