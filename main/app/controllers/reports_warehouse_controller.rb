class ReportsWarehouseController < ApplicationController
  layout false

  def get_report_file
    target_file_path = "." + request.fullpath.to_s
    if !params[:any_path].blank? && File.exist?(target_file_path)
      path_arr = params[:any_path].split("/")
      current_group = nil

      # 在线测试
      if path_arr.include?("online_tests")
        if path_arr.include?(Common::OnrineTest::Group::Individual)
          current_group = Common::OnrineTest::Group::Individual
          group_ids = [current_wx_user.id]
        elsif path_arr.include?(Common::OnrineTest::Group::Total)
          current_group = Common::OnrineTest::Group::Total
          group_ids = current_wx_user.online_tests.map{|item| item.id.to_s}
        end
      # 一般测试
      else
        path_h = {}
        generic_re = /[0-9a-zA-Z]{1,}\.json$/
        nav_re = /(nav\.json)$/
        ckps_qzps_mapping_re = /(ckps_qzps_mapping\.json)$/
        qzps_ckps_mapping_re = /(qzps_ckps_mapping\.json)$/
        paper_info_re = /(paper_info\.json)$/

        Common::Report::Group::ListArr.map{|item| path_h[item] = {:value => nil, :allowed_file_regx => [generic_re]} }
        # 学生
        if current_user.is_pupil?
          # current_group = Common::Report::Group::Pupil
          # group_ids = [current_user.pupil.uid]

          start_index = Common::Report::Group::ListArr.find_index(Common::Report::Group::Pupil)
          
          path_h[Common::Report::Group::Pupil][:value] = [current_user.role_obj.uid]
          path_h[Common::Report::Group::Klass][:value] = [current_user.role_obj.location.uid]
          path_h[Common::Report::Group::Grade][:value] = [current_user.tenant.uid]
          target_papers = current_user.role_obj.papers
          # path_h[Common::Report::Group::Project][:value] = current_user.role_obj.papers.map{|item| item.bank_tests[0].id.to_s if item.bank_tests[0]}.compact
          path_h[Common::Report::Group::Project][:allowed_file_regx] += [paper_info_re]

        # 教师
        elsif current_user.is_teacher?
          # current_group = Common::Report::Group::Grade
          # group_ids = [current_user.tenant.uid]

          start_index = Common::Report::Group::ListArr.find_index(Common::Report::Group::Pupil)

          path_h[Common::Report::Group::Pupil][:value] = current_user.role_obj.pupils.map{|item| item.uid}
          path_h[Common::Report::Group::Klass][:value] = current_user.role_obj.locations.map{|item| item.uid}
          path_h[Common::Report::Group::Klass][:allowed_file_regx] += [nav_re]
          path_h[Common::Report::Group::Grade][:value] = [current_user.tenant.uid]
          target_papers = current_user.role_obj.papers
          # path_h[Common::Report::Group::Project][:value] =  current_user.role_obj.papers.map{|item| item.bank_tests[0].id.to_s if item.bank_tests[0]}.compact
          path_h[Common::Report::Group::Project][:allowed_file_regx] += [paper_info_re]

        # 分析员
        elsif current_user.is_analyzer?
          # current_group = Common::Report::Group::Grade
          # group_ids = [current_user.tenant.uid]

          start_index = Common::Report::Group::ListArr.find_index(Common::Report::Group::Grade)

          path_h[Common::Report::Group::Klass][:allowed_file_regx] += [nav_re] 
          path_h[Common::Report::Group::Grade][:value] = [current_user.tenant.uid]
          path_h[Common::Report::Group::Grade][:allowed_file_regx] += [nav_re]
          target_papers = current_user.role_obj.papers
          # path_h[Common::Report::Group::Project][:value] = current_user.role_obj.papers.map{|item| item.bank_tests[0].id.to_s if item.bank_tests[0]}.compact
          path_h[Common::Report::Group::Project][:allowed_file_regx] += [paper_info_re]

        # 租户管理员
        elsif current_user.is_tenant_administrator?
          # current_group = Common::Report::Group::Grade
          # group_ids = [current_user.tenant.uid]

          start_index = Common::Report::Group::ListArr.find_index(Common::Report::Group::Grade)

          path_h[Common::Report::Group::Klass][:allowed_file_regx] += [nav_re]
          path_h[Common::Report::Group::Grade][:value] = [current_user.tenant.uid]
          path_h[Common::Report::Group::Grade][:allowed_file_regx] += [nav_re]
          target_papers = current_user.tenant.papers
          # path_h[Common::Report::Group::Project][:value] = current_user.tenant.papers.map{|item| item.bank_tests[0].id.to_s if item.bank_tests[0]}.compact
          path_h[Common::Report::Group::Project][:allowed_file_regx] += [paper_info_re] 
        # 项目管理员
        elsif current_user.is_project_administrator?
          # current_group = Common::Report::Group::Project
          # group_ids = current_user.bank_tests.map{|item| item.id.to_s }

          start_index = Common::Report::Group::ListArr.find_index(Common::Report::Group::Project)

          path_h[Common::Report::Group::Klass][:allowed_file_regx] += [nav_re]
          path_h[Common::Report::Group::Grade][:allowed_file_regx] += [nav_re]
          target_papers = current_user.role_obj.papers
          # path_h[Common::Report::Group::Project][:value] = current_user.role_obj.papers.map{|item| item.bank_tests[0].id.to_s if item.bank_tests[0]}.compact
          path_h[Common::Report::Group::Project][:allowed_file_regx] += [paper_info_re, nav_re] 
        end
      end
      path_h[Common::Report::Group::Project][:value] = Mongodb::BankTest.where(bank_paper_pap_id: {"$in" => target_papers.only(:_id).map{|a| a._id.to_s }}).map{|item| item.id.to_s}#target_papers.map{|item| item.bank_tests[0].id.to_s if item.bank_tests[0]}.compact

      # if !((path_arr&["nav", "ckps_qzps_mapping", "qzps_ckps_mapping", "paper_info"]).size > 0)
        # 检查Group ID
        target_groups = Common::Report::Group::ListArr[start_index..-1]
        kaku_group_check_flags = target_groups.map{|group|
          group_index_in_path = path_arr.find_index(group)
          group_id = group_index_in_path.nil?? nil : path_arr[group_index_in_path + 1]
          group_index_in_path.nil?? true : (path_h[group][:value].include?(group_id) && path_h[group][:allowed_file_regx].map{|item| item.match(path_arr[-1]+".json").blank? }.include?(false) )
        }

        # group_id = path_arr[group_index_in_path + 1]
        # if group_ids.compact.include?(group_id)
        unless kaku_group_check_flags.uniq.include?(false)
          expires_in 7.days, :public => true
          response.headers['Content-Type'] = "application/json"
          send_file target_file_path
        else
          render status: 200, :json => { status: 401, message: "Access not allowed!" }.to_json
        end
      # elsif ((path_arr&["nav", "ckps_qzps_mapping", "qzps_ckps_mapping", "paper_info"]).size > 0)
      #   data = File.open(target_file_path, 'rb').read
      #   data.force_encoding(Encoding::UTF_8)
      # else
      #   status 404
      #   { message: Common::Locale::i18n("swtk_errors.object_not_found", :message => request.fullpath.to_s ) }
      # end
    else
      render status: 404, :json => { message: Common::Locale::i18n("swtk_errors.object_not_found", :message => request.fullpath.to_s ) }.to_json
    end
  end

end
