# -*- coding: UTF-8 -*-

module ReportsWarehouse
  class API < Grape::API
    version 'v1.1', using: :path #/api/v1/<resource>/<action>
    format :json
    prefix :api

    helpers ApiHelper

    resource :reports_warehouse do
      before do
        wx_set_api_header
        #wx_authenticate!
      end

      #
      desc ''
      params do

      end
      post '*any_path' do
        target_file_path = "." + request.fullpath.to_s
        target_file_path = "." + request.fullpath.to_s.split("/api/v1.1")[1]

        if !params[:any_path].blank? && File.exist?(target_file_path)
          path_arr = params[:any_path].split("/")
          current_group = nil
          # 学生
          if wx_current_user.is_pupil?
            current_group = Common::Report::Group::Pupil
            group_ids = [wx_current_user.pupil.uid]
          # 教师
          elsif wx_current_user.is_teacher?
            current_group = Common::Report::Group::Grade
            group_ids = [wx_current_user.tenant.uid]
          # 分析员
          elsif wx_current_user.is_analyzer?
            current_group = Common::Report::Group::Grade
            group_ids = [wx_current_user.tenant.uid]
          # 租户管理员
          elsif wx_current_user.is_tenant_administrator?
            current_group = Common::Report::Group::Grade
            group_ids = [wx_current_user.tenant.uid]
          # 项目管理员
          elsif wx_current_user.is_project_administrator?
            current_group = Common::Report::Group::Project
            group_ids = wx_current_user.bank_tests.map{|item| item.id.to_s }
          end

          if path_arr.include?(current_group) && !((path_arr&["nav", "ckps_qzps_mapping", "qzps_ckps_mapping", "paper_info"]).size > 0)
            # 检查Group ID
            group_index_in_path = path_arr.find_index(current_group)
            group_index_in_path = group_index_in_path || 0
            group_id = path_arr[group_index_in_path + 1]
            if group_ids.compact.include?(group_id)
              data = File.open(target_file_path, 'rb').read
              data.force_encoding(Encoding::UTF_8)
            else
              status 401
              { message: "Access not allowed!" }
            end
          elsif ((path_arr&["nav", "ckps_qzps_mapping", "qzps_ckps_mapping", "paper_info"]).size > 0)
            data = File.open(target_file_path, 'rb').read
            data.force_encoding(Encoding::UTF_8)
          else
            status 404
            { message: Common::Locale::i18n("swtk_errors.object_not_found", :message => request.fullpath.to_s ) }
          end
        else
            status 404
            { message: Common::Locale::i18n("swtk_errors.object_not_found", :message => request.fullpath.to_s ) }
        end
      end
    end
  end
end