# -*- coding: UTF-8 -*-

module ApiV12Reports
  class API < Grape::API
    format :json

    helpers ApiV12Helper
    helpers ApiV12SharedParamsHelper
    helpers Doorkeeper::Grape::Helpers

    helpers do
      def read_report_data report_path
        result = {}
        if Common::SwtkRedis::has_key? Common::SwtkRedis::Ns::Cache, report_path
          target_report_j = Common::SwtkRedis::get_value Common::SwtkRedis::Ns::Cache, report_path
          result = JSON.parse(target_report_j)
        else
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
        temp_h = read_report_data(paper_info_path)
        return {} if temp_h.blank?
        result["paper_info"] = temp_h

        # 获取个分组报告信息
        group_arr.each{|group|
          group_index = url_arr.find_index{|item| item == group}
          next if group_index.blank?
          target_report_path = Common::Report::WareHouse::ReportLocation + url_arr[0..(group_index+1)].join("/") + ".json"
          temp_h = read_report_data(target_report_path)
          return {} if temp_h.blank?
          result[group] = temp_h
        }
        return result
      end
    end

    params do
      #use :oauth
    end

    resource :reports do
      before do
        set_api_header
        doorkeeper_authorize!
      end

      ###########

      desc ''
      params do
        #
      end
      post :list do
        target_user = current_user
        if target_user.is_pupil? || target_user.is_teacher? || target_user.is_analyzer? 
          target_papers = target_user.role_obj.papers.only(:id,:heading,:paper_status,:subject,:quiz_type,:quiz_date,:score)
        elsif target_user.is_tenant_administrator? || target_user.is_project_administrator? || target_user.is_area_administrator?
          target_tenant_ids = target_user.accessable_tenants.map(&:uid).uniq.compact
          target_test_ids = Mongodb::BankTestTenantLink.where(tenant_uid: {"$in" => target_tenant_ids} ).map(&:bank_test_id).uniq.compact
          target_pap_ids = Mongodb::BankTest.where(id: {"$in" => target_test_ids} ).map(&:bank_paper_pap_id).uniq.compact
          target_papers = Mongodb::BankPaperPap.where(id: {"$in" => target_pap_ids} ).only(:id,:heading,:paper_status,:subject,:quiz_type,:quiz_date,:score)
        else
          target_papers = []          
        end
        target_papers.compact!
        target_papers.uniq!

        unless target_papers.blank?
          if target_user.is_pupil?
            _rpt_type = Common::Report::Group::Pupil
            _rpt_id = target_user.role_obj.uid
          elsif target_user.is_tenant_administrator? || target_user.is_analyzer? || target_user.is_teacher?
            _rpt_type = Common::Report::Group::Grade
            _rpt_id = target_user.accessable_tenants.blank?? "" : target_user.accessable_tenants.first.uid
          elsif target_user.is_project_administrator? || target_user.is_area_administrator?
            _rpt_type = Common::Report::Group::Project
            _rpt_id = nil
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
              test_ext_data_path = target_pap.bank_tests[0].ext_data_path
              rpt_type = _rpt_type || Common::Report::Group::Project
              rpt_id = (_rpt_type == Common::Report::Group::Project)? test_id : _rpt_id
              report_url = Common::Report::get_test_report_url(test_id, rpt_type, rpt_id)
              {
                :paper_heading => target_pap.heading,
                :subject => Common::Locale::i18n("dict.#{target_pap.subject}"),
                :quiz_type => Common::Locale::i18n("dict.#{target_pap.quiz_type}"),
                :quiz_date => target_pap.quiz_date.strftime('%Y/%m/%d'),
                :score => target_pap.score,
                :report_version => "00016110",
                :test_id => test_id,
                :test_ext_data_path => test_ext_data_path,
                :report_url => "/api/v1.2" + report_url
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
        #
      end
      post :list2 do
        target_user = current_user
        if target_user.is_area_administrator?
          target_tests = target_user.role_obj.area.bank_tests
        elsif target_user.is_tenant_administrator?
          target_tests = target_user.accessable_tenants.map{|t| t.bank_tests}.flatten
          _rpt_type = Common::Report::Group::Grade
          _rpt_id = target_user.accessable_tenants.blank?? "" : target_user.accessable_tenants.last.uid          
        elsif target_user.is_teacher?
          target_tests = target_user.accessable_locations.map{|l| l.bank_tests}.flatten
          _rpt_type = Common::Report::Group::Grade
          _rpt_id = target_user.accessable_tenants.blank?? "" : target_user.accessable_tenants.last.uid
        elsif target_user.is_pupil?
          target_tests = target_user.bank_tests
          _rpt_type = Common::Report::Group::Pupil
          _rpt_id = target_user.role_obj.uid
        else
          target_tests = []
        end
        target_tests.compact!
        target_tests.uniq!

        target_tests.map{|t|
          test_id = t.id.to_s
          target_pap = t.paper_question
          next unless target_pap
          rpt_type = _rpt_type || Common::Report::Group::Project
          rpt_id = _rpt_id || test_id
          report_url = Common::Report::get_test_report_url(test_id, rpt_type, rpt_id)
          {
            :paper_heading => target_pap.heading,
            :quiz_type => Common::Locale::i18n("dict.#{target_pap.quiz_type}"),
            :quiz_date => target_pap.quiz_date.strftime('%Y/%m/%d'),
            :report_version => "00016110",
            :test_id => test_id,
            :report_url => "/api/v1.2" + report_url
          }
        }.compact
      end

      ###########

      desc ''
      params do
        optional :private, type: Boolean, default: false 
      end
      post :my_list do
        target_user = current_user
        if params[:private]
          target_tests = target_user.accessable_tests.find_all{|item| !item.is_public }
          _group_arr = Common::Report2::Group::List2Arr
        else
          target_tests = target_user.bank_tests.find_all{|item| item.is_public }
          _group_arr = Common::Report2::Group::List1Arr
        end
        _rpt_type,_rpt_id = target_user.report_top_group_kv(!params[:private])

        target_tests.map{|item|
          next unless item
          test_id = item.id.to_s
          rpt_type = _rpt_type || _group_arr[-1]
          rpt_id = _rpt_id || test_id
          report_url = Common::Report::get_test_report_url(test_id, rpt_type, rpt_id)
          {
            :name => item.name,
            :quiz_type => Common::Locale::i18n("dict.#{item.quiz_type}"),
            :start_date => item.start_date ? item.start_date.strftime('%Y/%m/%d %H:%M') : nil,
            :end_date => item.quiz_date ? item.quiz_date.strftime('%Y/%m/%d %H:%M') : nil,
            :report_version => "1.2",
            :test_id => test_id,
            :report_url => "/api/v1.2" + report_url
          }
        }
      end

      ###########
      desc '获取当前用户所在租户的年级班级列表 post /api/v1.2/reports/klass_list' # class_list begin
      params do
        requires :test_id, type: String, allow_blank: false
        requires :tenant_uid, type: String, allow_blank: false
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
        nav_path = Common::Report::WareHouse::ReportLocation  + "reports_warehouse/tests/" + params[:test_id]+ '/.*grade/' + params[:tenant_uid] + '/nav.json$'
        re = Regexp.new nav_path
        nav = Mongodb::TestReportUrl.where(test_id: params[:test_id], report_url: re).first
        nav_data = File.open(nav.report_url, 'rb').read if nav
        nav_h = JSON.parse(nav_data) if !nav_data.blank?
        result = nav_h.values[0].map{|item| item if accessable_loc_uids.include?(item[1]["uid"])}.compact if !nav_h.values.blank?

        result
      end # class_list end

      ###########

      desc '获取学生报告 post /api/v1.2/reports/pupil' # pupil report begin
      params do
        requires :report_url, type: String, allow_blank: false
      end
      post :pupil do
        construct_report_content(Common::Report::Group::Pupil, params[:report_url])
      end # pupil report end

      ###########         

      desc '获取班级报告 post /api/v1.2/reports/klass' # klass report begin
      params do
        requires :report_url, type: String, allow_blank: false
      end
      post :klass do
        construct_report_content(Common::Report::Group::Klass, params[:report_url])
      end # klass report end

      ###########

      desc '获取年级报告 post /api/v1.2/reports/grade' # grade report begin
      params do
        requires :report_url, type: String, allow_blank: false
      end
      post :grade do
        construct_report_content(Common::Report::Group::Grade, params[:report_url])
      end # grade report end

      ###########

      desc '获取区域报告 post /api/v1.2/reports/project' # project report begin
      params do
        requires :report_url, type: String, allow_blank: false
      end
      post :project do
        construct_report_content(Common::Report::Group::Project, params[:report_url])
      end # project report end

      ###########

      desc '获取综合素质报告 post /api/v1.2/reports/zh_my_report' # zh_my_report begin
      params do

      end
      post :project do

      end # zh_my_report end

      ###########

    end

   end
end