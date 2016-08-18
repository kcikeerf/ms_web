module UsersHelper
  def user_popup_menus
    if current_user.is_pupil?
      menus = {personal_center: my_home_pupils_path}
    elsif current_user.is_teacher?
      menus = {personal_center: my_home_teachers_path}
    elsif current_user.is_analyzer?
      menus = {personal_center: my_home_analyzers_path}
    elsif current_user.is_tenant_administrator?
      menus = {personal_center: my_home_tenant_administrators_path}
    end
#    menus[:account_setting] = url_for(action: 'setting', controller: 'accounts')
    menus[:edit_password] = edit_user_registration_path
    menus[:logout] = destroy_user_session_path
    return menus
  end

  def left_panel_menus
    if current_user.is_pupil?
      menus = {
        my_home: my_home_pupils_path,
        my_report: my_report_pupils_path
      }
    elsif current_user.is_teacher?
      menus = {
        my_home: my_home_teachers_path,
        my_pupil: my_pupil_teachers_path,
        test_report: test_report_teachers_path
      }
    elsif current_user.is_analyzer?
      menus = {
        my_home: my_home_analyzers_path,
        my_paper: my_paper_analyzers_path,
        my_log: my_log_analyzers_path
      }
    elsif current_user.is_tenant_administrator?
      menus = {
        my_home: my_home_tenant_administrators_path,
        my_analyzer: my_analyzer_tenant_administrators_path, 
        my_teacher: my_teacher_tenant_administrators_path, 
        my_paper: my_paper_tenant_administrators_path
      }
    end
    return menus
  end

  def left_pabel_menus_in_account_binding
    menus = {
      registrations: edit_user_registration_path,
      profiles: account_binding_profile_path
    }
    return menus
  end

  def get_role_label
    if current_user.is_pupil?
      I18n.t("dict.pupil")
    elsif current_user.is_teacher?
      I18n.t("dict.teacher")
    elsif current_user.is_analyzer?
      I18n.t("dict.analyzer")
    end
  end

  def user_avatar(image, type='')
    return 'uploadavatar.png' unless image
    type.blank? ? image.file.url : image.file.send(type.to_sym).url
  end

end
