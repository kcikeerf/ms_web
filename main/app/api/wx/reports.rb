# -*- coding: UTF-8 -*-

module Reports
  class API < Grape::API
    version 'v1.1', using: :path #/api/v1/<resource>/<action>
    format :json
    prefix "api/wx".to_sym

    helpers ApiHelper
    helpers SharedParamsHelper

    helpers do
      def read_report_data report_path
        result = {}
        if Common::SwtkRedis::has_key? Common::SwtkRedis::Ns::Cache, report_path
          puts "true"
          target_report_j = Common::SwtkRedis::get_value Common::SwtkRedis::Ns::Cache, report_path
          result = JSON.parse(target_report_j)
        else
          puts "false"
          target_report_f = Dir[report_path].first
          return result if target_report_f.blank?
          target_report_data = File.open(target_report_f, 'rb').read
          return result if target_report_data.blank?
          result = JSON.parse(target_report_data)
          Common::SwtkRedis::set_key Common::SwtkRedis::Ns::Cache, report_path, result.to_json
        end
        return result
      end

      def construct_report_content current_group, report_url
        result = {}
        report_url.sub!(".json","")
        url_arr = report_url.split("/")
        return result if url_arr.blank? || !url_arr.include?("tests")

        group_start_index = Common::Report::Group::ListArr.find_index{|item| item == current_group }
        group_arr = Common::Report::Group::ListArr[group_start_index..-1]
        # 获取试卷信息
        tests_index = url_arr.find_index{|item| item == "tests"}
        paper_info_path = Common::Report::WareHouse::ReportLocation + url_arr[0..(tests_index + 1)].join("/") + "/paper_info.json"        
        result["paper_info"] = read_report_data(paper_info_path)

        # 获取个分组报告信息
        group_arr.each{|group|
          group_index = url_arr.find_index{|item| item == group}
          target_report_path = Common::Report::WareHouse::ReportLocation + url_arr[0..(group_index+1)].join("/") + ".json"
          result[group] = read_report_data(target_report_path)
        }
        return result
      end
    end

    resource :reports do
      before do
        set_api_header
        authenticate!
      end

      ###########

      desc ''
      params do
        use :authenticate
      end
      post :list do
        target_user = current_user
        if target_user.is_pupil? || target_user.is_teacher? || target_user.is_analyzer? 
          target_papers = target_user.role_obj.papers
        elsif target_user.is_tenant_administrator? || target_user.is_project_administrator? || target_user.is_area_administrator?
          target_papers = target_user.accessable_tenants.map{|item| item.papers }.flatten
        else
          target_papers = []          
        end
        target_papers.compact!
        target_papers.uniq!

        unless target_papers.blank?
          if target_user.is_pupil?
            rpt_type = Common::Report::Group::Pupil
            rpt_id = target_user.role_obj.uid
          elsif target_user.is_tenant_administrator? || target_user.is_analyzer? || target_user.is_teacher?
            rpt_type = Common::Report::Group::Grade
            rpt_id = target_user.accessable_tenants.blank?? "" : target_user.accessable_tenants.first.uid
          else
            # do nothing
          end
          target_papers.map{|target_pap|
            next unless target_pap
            next if target_pap.paper_status != Common::Paper::Status::ReportCompleted
            if target_pap.bank_tests.blank? #兼容旧，适时删除掉
              if target_user.is_pupil? 
                target_report = Mongodb::PupilReport.where(pup_uid: target_user.role_obj.uid).first
                rpt_h = JSON.parse(target_report.report_json)
                {
                  :paper_heading => target_pap.heading,
                  :subject => rpt_h["basic"]["subject"],
                  :quiz_type => rpt_h["basic"]["quiz_type"],
                  :quiz_date => rpt_h["basic"]["quiz_date"],
                  :score => rpt_h["basic"]["score"],
                  :value_ratio => rpt_h["basic"]["value_ratio"],
                  :class_rank => rpt_h["basic"]["class_rank"],
                  :grade_rank => rpt_h["basic"]["grade_rank"],
                  :report_version => "000016090",
                  :report_id => target_report._id.to_s,
                  :dt_update => target_report.dt_update.strftime("%Y-%m-%d %H:%M")
                }
              end
            else
              test_id = target_pap.bank_tests[0].id.to_s
              rpt_type = rpt_type || Common::Report::Group::Project
              rpt_id = rpt_id || test_id
              report_url = Common::ReportPlus::report_url(test_id, rpt_type, rpt_id)
              {
                :paper_heading => target_pap.heading,
                :subject => Common::Locale::i18n("dict.#{target_pap.subject}"),
                :quiz_type => Common::Locale::i18n("dict.#{target_pap.quiz_type}"),
                :quiz_date => target_pap.quiz_date.strftime('%Y/%m/%d'),
                :score => target_pap.score,
                :report_version => "00016110",
                :test_id => test_id,
                :report_url => "/api/wx/v1.1" + report_url
              }
            end
          }.compact
        else
          []
        end
      end

      ###########

      desc ''
      params do
        use :authenticate
        #requires :quiz_type, type: String, allow_blank: false
      end
      post :list2 do
        target_user = current_user
        if target_user.is_area_administrator?
          target_tests = target_user.role_obj.area.bank_tests
        elsif target_user.is_tenant_administrator?
          target_tests = target_user.accessable_tenants.map{|t| t.bank_tests}.flatten
        elsif target_user.is_teacher?
          target_tests = target_user.accessable_locations.map{|l| l.bank_tests}.flatten      
        elsif target_user.is_pupil?
          target_tests = target_user.bank_tests
          rpt_type = Common::Report::Group::Pupil
          rpt_id = target_user.role_obj.uid
        else
          target_tests = []
        end
        target_tests.compact!
        target_tests.uniq!

        target_tests.map{|t|
          test_id = t.id.to_s
          target_pap = t.paper_question
          next unless target_pap
          rpt_type = rpt_type || Common::Report::Group::Project
          rpt_id = rpt_id || test_id      
          report_url = Common::ReportPlus::report_url(test_id, rpt_type, rpt_id)          
          {
            :paper_heading => target_pap.heading,
            :quiz_type => Common::Locale::i18n("dict.#{target_pap.quiz_type}"),
            :quiz_date => target_pap.quiz_date.strftime('%Y/%m/%d'),
            :report_version => "00016110",
            :test_id => test_id,
            :report_url => "/api/wx/v1.1" + report_url
          }
        }.compact
      end

      ###########

      desc '获取当前用户所在租户的年级班级列表 post /api/wx/v1.1/reports/klass_list' # class_list begin
      params do
        use :authenticate
        requires :test_id, type: String, allow_blank: false
        optional :tenant_uid, type: String, allow_blank: false
      end
      post :klass_list do
        result = []

        if params[:tenant_uid].blank?
          accessable_tenant_uids = current_user.accessable_tenants.map(&:uid)
          default_tenant_uid = accessable_tenant_uids[0]
        else
          default_tenant_uid = params[:tenant_uid]
        end
        accessable_loc_uids = current_user.accessable_locations.map(&:uid)
  
        nav_h = {}
        nav_f = Dir[Common::Report::WareHouse::ReportLocation + "reports_warehouse/tests/" + params[:test_id]+ '/**/grade/' + params[:tenant_uid] + '/nav.json'].first
        nav_data = File.open(nav_f, 'rb').read if !nav_f.blank?
        nav_h = JSON.parse(nav_data) if !nav_data.blank?
        result = nav_h.values[0].map{|item| item if accessable_loc_uids.include?(item[1]["uid"])}.compact if !nav_h.values.blank?

        result
      end # class_list end

      ###########

      desc '获取学生报告 post /api/wx/v1.1/reports/pupil' # pupil report begin
      params do
        use :authenticate
        requires :report_url, type: String, allow_blank: false
      end
      post :pupil do
        construct_report_content(Common::Report::Group::Pupil, params[:report_url])
      end # pupil report end

      ###########         

      desc '获取班级报告 post /api/wx/v1.1/reports/klass' # klass report begin
      params do
        use :authenticate
        requires :report_url, type: String, allow_blank: false
      end
      post :klass do
        construct_report_content(Common::Report::Group::Klass, params[:report_url])
      end # klass report end

      ###########

      desc '获取年级报告 post /api/wx/v1.1/reports/grade' # grade report begin
      params do
        use :authenticate
        requires :report_url, type: String, allow_blank: false
      end
      post :grade do
        construct_report_content(Common::Report::Group::Grade, params[:report_url])
      end # grade report end

      ###########

      desc '获取区域报告 post /api/wx/v1.1/reports/project' # project report begin
      params do
        use :authenticate
        requires :report_url, type: String, allow_blank: false
      end
      post :project do
        construct_report_content(Common::Report::Group::Project, params[:report_url])
      end # project report end

      ###########

    end

   end
end