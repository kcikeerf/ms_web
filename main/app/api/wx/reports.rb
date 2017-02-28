# -*- coding: UTF-8 -*-

module Reports
  class API < Grape::API
    version 'v1.1', using: :path #/api/v1/<resource>/<action>
    format :json
    prefix "api/wx".to_sym

    helpers ApiHelper
    helpers SharedParamsHelper

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
          target_papers.map{|target_pap|
            next unless target_pap
            next if target_pap.paper_status != Common::Paper::Status::ReportCompleted
            if target_pap.bank_tests.blank?
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
              {
                :paper_heading => target_pap.heading,
                :subject => Common::Locale::i18n("dict.#{target_pap.subject}"),
                :quiz_type => Common::Locale::i18n("dict.#{target_pap.quiz_type}"),
                :quiz_date => target_pap.quiz_date.strftime('%Y/%m/%d'),
                :score => target_pap.score,
                :report_version => "00016110",
                :test_id => target_pap.bank_tests[0].id.to_s,
                :report_url => "/api/wx/v1.1" + Common::ReportPlus::report_url(target_pap.bank_tests[0].id.to_s, target_user)
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
        else
          target_tests = []
        end
        target_tests.compact!
        target_tests.uniq!

        target_tests.map{|t|
          target_pap = t.paper_question
          next unless target_pap
          {
            :paper_heading => target_pap.heading,
            :quiz_type => Common::Locale::i18n("dict.#{target_pap.quiz_type}"),
            :quiz_date => target_pap.quiz_date.strftime('%Y/%m/%d'),
            :report_version => "00016110",
            :test_id => t.id.to_s,
            :report_url => "/api/wx/v1.1" + Common::ReportPlus::report_url(t.id.to_s, target_user)
          }
        }.compact
      end

      ###########

      desc '获取当前用户所在租户的年级班级列表 post /api/wx/v1.1/reports/klass_list' # grade_class_list begin
      params do
        use :authenticate
        requires :test_id, type: String, allow_blank: true
        optional :tenant_uid, type: String, allow_blank: true
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
        Find.find("/reports_warehouse/tests/#{params[:test_id]}"){|f|
          if f =~ /.*#{default_tenant_uid}\/nav.json/
            data = File.open(f, 'rb').read
            nav_h = JSON.parse(data)
            break
          end
        }

        nav_h.values[0].map{|item| item if accessable_loc_uids.include?(item[1]["uid"])}.compact

      end # grade_class_list end

      ###########      

    end

   end
end