module PapersHelper
  def download_list(type)
    ftype_arr = []
    case type
    when 'original_paper_answer'
      ftype_arr = %w{paper answer}
    when 'modified_paper_answer_emptyscore'
      ftype_arr = %w{revise_paper revise_answer empty_result}
    when 'imported_score'
      ftype_arr = %w{filled_file}
    when 'user_password_reporturl'
      ftype_arr = %w{usr_pwd_file}
    else
      # do nothing
    end
    ftype_arr.map{|ftype|
      {:pap_uid => @paper.id.to_s, :type => ftype, :tenant_uid=> params[:tenant_uid], :file_name => download_file_name(ftype)}
    }
  end

  def download_file_name type
    common_arr = [
      @paper.quiz_date.strftime('%Y') + Common::Locale::i18n('dict.nian'),
      Common::Grade::List[@paper.grade.to_sym],
      Common::Subject::List[@paper.subject.to_sym]
    ]
    common_info_str = common_arr.join("_")
    case type
    # when 'usr_pwd_file'
    #   if current_user.is_project_administrator?
    #     target_tenant = Tenant.find(params[:tenant_uid])
    #     result = target_tenant.name_cn + '_' + common_info_str + "_"
    #   else
    #     result = common_info_str + "_" + Common::Locale::i18n('reports.check') + "_"
    #   end
    # when 'filled_file'
    #   if current_user.is_project_administrator?
    #     target_tenant = Tenant.find(params[:tenant_uid])
    #     result = target_tenant.name_cn + '_' + common_info_str + "_"
    #   else
    #     result = @paper.heading + '_' + common_info_str + "_"
    #   end
    when "usr_pwd_file", 'filled_file'
      target_tenant = Tenant.find(params[:tenant_uid])
      result = target_tenant.name_cn + '_' + common_info_str + "_"
    else
      result = @paper.heading + '_' + common_info_str + "_"
    end
    result += Common::Locale::i18n("papers.name.#{type}")
    result
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
