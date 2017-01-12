module ApplicationHelper
  def success_notice(message)
    unless message.blank?
      "<div class='alert alert-success' role='alert'>#{flash[:notice]}</div>"
    end
  end

  def error_message(resource, column)
    raw "<small class='help-block'>#{resource.errors[column.to_sym].first}</small>" unless resource.errors[column.to_sym].blank?
  end

  #local i18n abbrev
  def LABEL str
    Common::Locale::i18n(str)
  end

  def subject_list
    Common::Subject::List
  end

  def grade_list
      Common::Grade::List 
  end

  def classroom_list
      Common::Klass::List 
  end

  def node_version_list
      Common::NodeVersion::List
  end

  def term_list
      Common::Term::List
  end

  def sex_list
      Common::Locale::SexList
  end

  def quiz_type_list
      Common::Paper::QuizType
  end

  def difficulty_list
    Common::Paper::Difficulty
  end

  #地区列表
  def area_list
    country_rid = Common::Area::CountryRids["zhong_guo"]
    country = Area.where("rid = '#{country_rid}'").first
    province_list = country.children_h.map{|a| OpenStruct.new({:rid=>a[:rid], :name_cn=>a[:name_cn]})}
    city_list = Area.default_option.map{|a| OpenStruct.new({:rid=>a[:rid], :name_cn=>a[:name_cn]})}
    district_list = Area.default_option.map{|a| OpenStruct.new({:rid=>a[:rid], :name_cn=>a[:name_cn]})}
    return {
      :province => province_list,
      :city => city_list,
      :district => district_list
    }
  end

  def cdn_path version
    result = "http://#{Common::SwtkConstants::CDNDomain}/assets/"
    case version
    when "1.0"
      result += Common::SwtkConstants::CDNVersion1_0
    when "1.1"
      result += Common::SwtkConstants::CDNVersion1_1
    end
    result += "/"
    return result
  end
end
