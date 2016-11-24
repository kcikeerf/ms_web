class ReportsWarehouseController < ApplicationController
  layout false

  def get_report_file
    target_file_path = "." + request.fullpath.to_s
    if !params[:any_path].blank? && File.exist?(target_file_path)
      path_arr = params[:any_path].split("/")
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
      unless path_arr.include?(current_group)
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
