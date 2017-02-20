# -*- coding: UTF-8 -*-

class Area < ActiveRecord::Base
  self.primary_key = "uid"

  #concerns
  include TimePatch
  include InitUid

  has_many :tenants, foreign_key: "area_uid"
  has_many :area_administrators, foreign_key: "area_uid"

  has_many :users, foreign_key: "area_uid"

  ########类方法定义：begin#######
  class << self
    def get_area params
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

    def get_area_by_name params
      name_str = "zhong_guo"
      if params[:district]
        name_str = params[:district]
      elsif params[:city]
        name_str = params[:city]
      elsif params[:province]
        name_str = params[:province]
      end
      result = Area.where(:name => name_str).first
      return result
    end  

    def get_area_uid_rid params
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
  
    def default_option
      result = [{
        :uid=> "", 
        :rid=> "", 
        :name=> "all", 
        :name_cn=> Common::Locale::i18n("areas.list.all")}]
    end
  end
  ########类方法定义：end#######

  def papers
    Mongodb::BankPaperPap.where(:area_uid => rid).to_a
  end

  #根据rid获取省市区的hash
  def pcd_h
    result = {
      :province => {},
      :city => {},
      :district => {}
    }
    case area_type
    when Common::Area::Type::Province
      result[:province][:uid] = uid
      result[:province][:rid] = rid
      result[:province][:name] = name
      result[:province][:name_cn] = name_cn
    when Common::Area::Type::City
      result[:province][:uid] = parent.uid
      result[:province][:rid] = parent.rid
      result[:province][:name] = name
      result[:province][:name_cn] = parent.name_cn
      result[:city][:uid] = uid
      result[:city][:rid] = rid
      result[:city][:name] = name
      result[:city][:name_cn] = name_cn
    when Common::Area::Type::District
      result[:province][:uid] = parent.uid
      result[:province][:rid] = parent.parent.rid
      result[:province][:name] = name
      result[:province][:name_cn] = parent.parent.name_cn
      result[:city][:uid] = uid
      result[:city][:rid] = parent.rid
      result[:city][:name] = name
      result[:city][:name_cn] = parent.name_cn
      result[:district][:uid] = uid
      result[:district][:rid] = rid
      result[:district][:name] = name
      result[:district][:name_cn] = name_cn
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

  def families
    self.class.where("rid LIKE '#{rid}%'")
  end

  def all_tenants
    families.map{|f| f.tenants}.flatten
  end

  def bank_tests
    Mongodb::BankTestAreaLink.where(area_uid: self.uid).map{|item| item.bank_test}.compact
  end
end
