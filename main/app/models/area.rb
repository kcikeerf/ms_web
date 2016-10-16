# -*- coding: UTF-8 -*-

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

  #根据rid获取省市区的hash
  def pcd_h
    result = {
      :province => {:rid => ""},
      :city => {:rid => ""},
      :district => {:rid => ""}
    }
    case area_type
    when Common::Area::Type::Province
      result[:province][:rid] = rid
    when Common::Area::Type::City
      result[:province][:rid] = parent.rid
      result[:city][:rid] = rid
    when Common::Area::Type::District
      result[:province][:rid] = parent.parent.rid
      result[:city][:rid] = parent.rid
      result[:district][:rid] = rid
    end
    return result
  end

  def parent
    rid_len = rid.length
    if rid_len > Common::SwtkConstants::CkpStep
      p_rid = rid.slice(0, (rid_len - Common::SwtkConstants::CkpStep))
      cond_str = "rid = '#{p_rid}'"
      self.class.where(cond_str).first
    else
      OpenStruct.new(Area.default_option)
    end
  end

  def children
    rid_len = rid.length
    rid_len_max = rid.length + Common::SwtkConstants::CkpStep
    cond_str = "rid LIKE '#{rid}%' and LENGTH(rid) > #{rid_len} and LENGTH(rid) <= #{rid_len_max}"
    self.class.where(cond_str)
  end

  def children_h
    result = Area.default_option
    result + children.map{|c| {:uid=> c.uid, :rid=> c.rid, :name=> c.name, :name_cn=>c.name_cn}}
  end

  def self.default_option
    result = [{
      :uid=> "", 
      :rid=> "", 
      :name=> "all", 
      :name_cn=> Common::Locale::i18n("areas.list.all")}]
  end

  def all_tenants
    families.map{|f| f.tenants}.flatten
  end

  # def self.provinces rid
  #   Area.where("rid = ? and LENGTH(rid) >= 3 and LENGTH(rid) <= 6", rid)
  # end

  # def self.cities rid
  #   Area.where("rid = ? and LENGTH(rid) >= 7 and LENGTH(rid) <= 9", rid)
  # end

  # def self.districts rid
  #   Area.where("rid = ? and LENGTH(rid) >= 10 and LENGTH(rid) <= 12", rid)
  # end

  def self.get_area params
    name_pinyin = "zhong_guo"
    if params[:district]
      name_pinyin = Common::Locale::hanzi2pinyin(params[:district])
    elsif params[:city]
      name_pinyin = Common::Locale::hanzi2pinyin(params[:city])
    elsif params[:province_rid]
      name_pinyin = Common::Locale::hanzi2pinyin(params[:province])
    end
    result = Area.where(:name => name_pinyin).first
    return result
  end  

  def self.get_area_uid_rid params
    areaUid = ""
    areaRid = ""
    if params[:district_rid]
      target_area = Area.where(:rid => params[:district_rid]).first
      areaRid = params[:district_rid]
    elsif params[:city_rid]
      target_area = Area.where(:rid => params[:city_rid]).first
      areaRid = params[:city_rid]
    elsif params[:province_rid]
      target_area = Area.where(:rid => params[:province_rid]).first
      areaRid = params[:province_rid]
    end
    areaUid = target_area.uid if target_area
    return areaUid,areaRid  
  end
end
