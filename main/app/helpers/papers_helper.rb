module PapersHelper
  def download_list(type)		
    case type
    when 'original_paper_answer'
      %w{paper answer}
    when 'modified_paper_answer_emptyscore'
      %w{revise_paper revise_answer empty_file}
    when 'imported_score'
      %w{filled_file}
    when 'user_password_reporturl'
      %w{usr_pwd_file}
    else
      []
    end
  end

  def test_organizer_name
    result = ""
    if current_user.is_project_administrator?
      result = Common::Locale::i18n("tenants.types.xue_xiao_lian_he")
    else
      result = current_tenant.name_cn
    end
    return result
  end
end
