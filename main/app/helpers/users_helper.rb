module UsersHelper
  def top_title
    result = ""
    if current_user.is_project_administrator?
      result = current_user.role_obj.name
    else
      result = current_tenant.name_cn
    end
    return result
  end

  def user_popup_menus
    # if current_user.is_pupil?
    #   menus = {personal_center: my_home_pupils_path}
    # elsif current_user.is_teacher?
    #   menus = {personal_center: my_home_teachers_path}
    # elsif current_user.is_analyzer?
    #   menus = {personal_center: my_home_analyzers_path}
    # elsif current_user.is_tenant_administrator?
    #   menus = {personal_center: my_home_tenant_administrators_path}
    # elsif current_user.is_project_administrator?
    #   menus = {personal_center: my_home_project_administrators_path}
    # end
#    menus[:account_setting] = url_for(action: 'setting', controller: 'accounts')
    menus = {}
    menus[:personal_center] = my_home_users_path
    menus[:edit_password] = edit_user_registration_path
    menus[:logout] = destroy_user_session_path
    return menus
  end

  def left_panel_menus
    menus = {}
    menus[:my_home] = my_home_users_path
    if current_user.is_pupil?
      menus[:my_report] = my_report_users_path
    elsif current_user.is_teacher?
      menus[:my_pupil] = my_pupil_users_path
      menus[:test_report] = test_report_users_path
    elsif current_user.is_analyzer?
      menus[:my_paper] = my_paper_users_path
    elsif current_user.is_tenant_administrator?
      menus[:my_analyzer] = my_analyzer_users_path
      menus[:my_teacher] = my_teacher_users_path
      menus[:my_paper] = my_paper_users_path
    elsif current_user.is_project_administrator?
      menus[:my_exam] = my_exam_users_path
      menus[:my_paper] = my_paper_users_path

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

  def profile_info_items
    items = []
    if current_user.is_project_administrator?
      items = ["name", "phone", "qq", "email"]
    elsif current_user.is_tenant_administrator?
      items = ["name", "tenant","phone", "qq", "email"]
    elsif current_user.is_analyzer?
      items = ["name", "tenant","subject", "phone", "qq", "email"]
    elsif current_user.is_teacher?
      items = ["name", "tenant","subject", "phone", "qq", "email"]
    elsif current_user.is_pupil?
      items = ["name", "sex", "tenant", "grade", "classroom", "phone", "qq", "email"]
    else
      items = ["name"]
    end
    return items
  end

  def edittable_info_items
    items = []
    if current_user.is_project_administrator?
      items = ["name", "qq"]
    elsif current_user.is_tenant_administrator?
      items = ["name","qq"]
    elsif current_user.is_analyzer?
      items = ["name", "subject", "qq"]
    elsif current_user.is_teacher?
      items = ["name", "subject",  "qq" ]
    elsif current_user.is_pupil?
      items = ["name", "grade", "classroom",  "qq"]
    else
      items = ["name"]
    end
    return items
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

  def current_tenant
    return nil if current_user.is_project_administrator?
    current_user.tenant
  end

  #
  #等角色权限控制之后，可以去掉
  def can_add_paper?
    (current_user.is_project_administrator? || current_user.is_analyzer?) && (action_name=="my_paper")
  end
end
