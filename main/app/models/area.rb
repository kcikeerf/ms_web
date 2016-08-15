class Area < ActiveRecord::Base
  self.primary_key = "uid"

  #concerns
  include TimePatch
  include InitUid

  has_many :tenants, foreign_key: "area_uid"

  def papers
    Mongodb::BankPaperPap.where(:area_uid => rid).to_a
  end

  def families
    self.class.where("rid LIKE '#{rid}%'")
  end

  def all_tenants
    families.map{|f| f.tenants}.flatten
  end

  def self.get_area_uid params
    areaUid = params[:country].blank?? Common::Area::CountryRids["China"] : Common::Area::CountryRids[params[:country]]
    if params[:province]
      target_area = Area.where(:name => Common::Locale.hanzi2pinyin(params[:province])).first
    elsif params[:city]
      target_area = Area.where(:name => Common::Locale.hanzi2pinyin(params[:city])).first
    elsif params[:district]
      target_area = Area.where(:name => Common::Locale.hanzi2pinyin(params[:district])).first
    end
    areaUid = target_area.rid if target_area
    return areaUid    
  end
end
