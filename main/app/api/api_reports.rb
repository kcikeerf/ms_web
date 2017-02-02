# -*- coding: UTF-8 -*-

module ApiReports
  class APIV11 < Grape::API
    version 'v1.1', using: :path #/api/v1/<resource>/<action>
    format :json
    prefix "api/".to_sym

    helpers ApiCommonHelper
    helpers ApiAuthHelper

    resource :reports do
      before do
        set_api_header!
        @current_user = current_user
      end

      ###########

      desc '' # api list begin
      params do

      end
      get :list do
        if @current_user.is_pupil? || @current_user.is_teacher? || @current_user.is_analyzer? || @current_user.is_project_administrator?
          target_papers = @current_user.role_obj.papers
        elsif @current_user.is_tenant_administrator?
          target_papers = @current_user.tenant.papers
        else
          target_papers = nil
        end
        unless target_papers.blank?
          target_papers.map{|target_pap|
            next unless target_pap
            if target_pap.bank_tests.blank?
              target_report = Mongodb::PupilReport.where(pup_uid: target_pap.id.to_s).first
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
            else
              {
                :paper_heading => target_pap.heading,
                :subject => Common::Locale::i18n("dict.#{target_pap.subject}"),
                :quiz_type => Common::Locale::i18n("dict.#{target_pap.quiz_type}"),
                :quiz_date => target_pap.quiz_date.strftime('%Y/%m/%d'),
                :score => target_pap.score,
                :report_version => "00016110",
                :test_id => target_pap.bank_tests[0].id.to_s,
                :report_url => "/api/wx/v1.1" + Common::ReportPlus::report_url(target_pap.bank_tests[0].id.to_s, @current_user)
              }
            end
          }
        else
          [{}]
        end
      end # api list end

      ###########

      desc '' # api get_indivisual_report_part begin
      params do
        requires :report_id, type: String, allow_blank: false
      end
      get :indivisual_report_part do

        target_report = Mongodb::PupilMobileReport.where(:_id => params[:report_id]).first
        if target_report
          target_report.simple_report_wx_notbinded
        else
          status 404
          message_json("e40004")
        end

      end # api get_indivisual_report_part end

      ###########

      desc '' # api get_indivisual_report_1 begin
      params do
        requires :report_id, type: String, allow_blank: false
      end
      get :indivisual_report_1 do

        target_report = Mongodb::PupilMobileReport.where(:_id => params[:report_id]).first
        if target_report
          target_report.report_json.blank?? Common::Report::Format::PupilMobile.to_json : target_report.report_json
        else
          status 404
          message_json("e40004")
        end

      end # api get_indivisual_report_1 end

      ###########

      desc '' # api get_pupil_report begin
      params do
        requires :report_id, type: String, allow_blank: false
      end
      get :pupil_report do

        current_pupil = wx_current_user.nil?? nil : wx_current_user.pupil
        if current_pupil
          target_report = Mongodb::PupilReport.where(:_id => params[:report_id]).first
          if target_report
            target_report.report_json.blank?? Common::ReportPlus::PupilHoukoku.to_json : target_report.report_json
          else
            status 404
            message_json("e40004")
          end
        else
          status 500
          message_json("e50000")
        end

      end # api get_pupil_report end

      ###########
    end

   end
end