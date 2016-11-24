class ReportsWarehouseController < ApplicationController
  layout false

  def get_report_file
    target_file_path = "." + request.fullpath.to_s
    p !params[:any_path].blank?
    p target_file_path
    p File.exist?(target_file_path)
    if !params[:any_path].blank? && File.exist?(target_file_path)
      path_arr = params[:any_path].split("/")
      p
      current_group = nil
      if current_user.is_pupil?
        current_group = Common::Report::Group::Pupil
      elsif current_user.is_teacher?
        current_group = Common::Report::Group::Grade
      elsif current_user.is_analyzer?
        current_group = Common::Report::Group::Grade
      elsif current_user.is_tenant_administrator?
        current_group = Common::Report::Group::Grade
      elsif current_user.is_project_administrator?
        current_group = Common::Report::Group::Project
      end
      # group_index_in_path = path_arr.find_index(current_group)
      # group_id = path_arr[group_index_in_path + 1]
      # 下一步确认访问范围
      # project : test id
      # grade: tenant uid
      # pupil: pup uid
      #
      if !path_arr.include?(current_group) && !((path_arr&["nav", "ckps_qzps_mapping", "qzps_ckps_mapping", "paper_info"]).size > 0)
        render status: 404, :json => { message: Common::Locale::i18n("swtk_errors.object_not_found", :message => request.fullpath.to_s ) }.to_json
      else
        expires_in 7.days, :public => true
        response.headers['Content-Type'] = "application/json"
        send_file target_file_path
      end
    else
      render status: 404, :json => { message: Common::Locale::i18n("swtk_errors.object_not_found", :message => request.fullpath.to_s ) }.to_json
    end
  end

end
