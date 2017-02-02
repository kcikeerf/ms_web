# -*- coding: UTF-8 -*-

module ApiPapers
  class APIV11 < Grape::API
    version 'v1.1', using: :path #/api/v1/<resource>/<action>
    format :json
    prefix "api/".to_sym

    helpers ApiCommonHelper
    helpers ApiAuthHelper

    resource :papers do

      before do
        set_api_header!
        authenticate_token!
      end

      ###########

      desc '随机获取任一试卷 get /api/v1.1/papers/sample'
      params do
        requires :grade, type: String, allow_blank: false
        requires :term, type: String, allow_blank: false
        requires :subject, type: String, allow_blank: false
      end
      get :sample do
        params_h ={
          :can_online_test => nil,
          :grade => params[:grade],
          :term => params[:term],
          :subject => params[:subject]
        }
        target_pap = Mongodb::BankPaperPap.get_a_paper params_h
        # current_paper = Mongodb::BankPaperPap.where(_id: "578c8579980146652f56a3a8").first || Mongodb::BankPaperPap.get_a_paper(params_h)
        if target_pap
          paper_h = JSON.parse(target_pap.paper_json)
          ############################
          # 临时处理，待流程整理后处理
          paper_h["paper_html"] = ""
          paper_h["answer_html"] = ""
          paper_h["paper"]= ""
          ############################
          {
            #online_test_id: xxxx, #未来实现
            pap_uid: target_pap.id.to_s,
            paper_json: paper_h.to_json
          }
        else
          status 404
          message_json("e40004")
        end
      end

      ###########

      desc ''
      params do
        requires :wx_openid, type: String, allow_blank: false
        requires :pap_uid, type: String, allow_blank: false
        requires :bank_quiz_qizs, type: Array, allow_blank: false
      end
      post :quiz_scores do

        begin
          #未来视情况作JOB处理
          #保存成绩
          Mongodb::OnlineTest.where({:wx_openid=> params[:wx_openid],:pap_uid => params[:pap_uid]}).destroy_all
          target_mot = Mongodb::OnlineTest.new({
            :pap_uid => params[:pap_uid],
            :user_id => wx_current_user.nil?? "" : wx_current_user.id,
            :wx_openid => params[:wx_openid],
            :result_json => params.to_json 
          })
          raise SwtkErrors::SaveOnlineTestError.new(Common::Locale::i18n("online_tests.messages.error.save_failed")) unless target_mot.save

          #录入得分点
          #删除同一试卷的旧得分点
          Mongodb::MobileUserQizpointScore.where({:wx_openid => params[:wx_openid], :pap_uid => params[:pap_uid]}).destroy_all
          Mongodb::MobileUserQizpointScore.save_score params
          #分析成绩
          #Mongodb::MobileReportTotalAvgResult.where({'_id.wx_openid' => params[:wx_openid], '_id.pap_uid' => params[:pap_uid]}).destroy_all
          Mongodb::MobileReportTotalAvgResult.destroy_all
          #Mongodb::MobileReportBasedOnTotalAvgResult.where({'_id.wx_openid' => params[:wx_openid], '_id.pap_uid' => params[:pap_uid]}).destroy_all
          Mongodb::MobileReportBasedOnTotalAvgResult.destroy_all
          #Mongodb::PupilMobileReport.where({'_id.wx_openid' => params[:wx_openid], '_id.pap_uid' => params[:pap_uid]}).destroy_all
          Mongodb::PupilMobileReport.destroy_all
          pupil = wx_current_user.nil?? nil : wx_current_user.pupil
          mobile_report_generator = Mongodb::MobileUserReportGenerator.new({
              :pap_uid => params[:pap_uid],
  #            :pup_uid => pupil.nil?? "" : pupil.uid,
              :wx_openid => params[:wx_openid]
          })
          
          mobile_report_generator.cal_ckp_total_avg
          mobile_report_generator.add_avg_col
          mobile_report_generator.cal_based_on_total_avg
          mobile_report_generator.construct_simple
          mobile_report_generator.construct_ckp_charts
          mobile_report_generator.construct_weak_ckps
          mobile_report_generator.construct_knowledge_weak_ckps

          #获取报告id
          if pupil.nil?
            rparams = {
              :pap_uid => params[:pap_uid],
              :wx_openid => params[:wx_openid]
            }
          else
            rparams ={
              :pap_uid => params[:pap_uid],
              :pup_uid => pupil.uid,
              :wx_openid => params[:wx_openid]
            }
          end
          mobile_report = Mongodb::PupilMobileReport.where(rparams).first
          raise unless mobile_report

          {
            report_id: mobile_report._id.to_s, 
          }
        rescue Exception => ex
          status 500
          message_json("e50000")
        end

      end

      ###########
    end
  end
end