# -*- coding: UTF-8 -*-

class Wx::PapersController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :wx_authenticate!, :except => [:get_quizs]

  def get_quizs
  	params.permit!
  	result = response_json

  	if params[:wx_openid].blank?
      result = response_json(500, {message: I18n.t("wx_users.messages.warn.not_wx_user")})
  	elsif params[:grade].blank? || params[:term].blank? || params[:subject].blank?
      result = response_json(400, {message: I18n.t("wx_commons.messages.warn.invalid_params")})
    else
      params_h ={
      	:grade => params[:grade],
      	:term => params[:term],
      	:subject => params[:subject]
      }
      current_paper = Mongodb::BankPaperPap.get_a_paper params_h
      if current_paper
        paper_h = JSON.parse(current_paper.paper_json)
        # 临时处理，待流程整理后处理
        paper_h["paper_html"] = ""
        paper_h["answer_hmtl"] = ""
        result = response_json(200, {paper_json: paper_h.to_json})
      else
        result = response_json(400, {message: I18n.t("wx_papers.messages.info.no_paper")})
      end
    end

  	render :json => result
  end

  def submit_quiz_score
    params.permit!
    result = response_json

  	if params[:wx_openid].blank?
      result = response_json(500, {message: I18n.t("wx_users.messages.warn.not_wx_user")})
  	elsif params[:bank_quiz_qizs].blank?
      result = response_json(400, {message: I18n.t("wx_scores.messages.warn.no_quizs")})
    else
      begin
      	#未来视情况作JOB处理
      	#保存成绩
      	target_mot = Mongodb::OnlineTest.new({
      	  :pap_uid => params[:paper][:pap_uid],
      	  :user_id => wx_current_user.nil?? "" : wx_current_user.id,
      	  :wx_openid => params[:wx_openid],
      	  :result_json => params.to_json 
      	})
      	raise SwtkErrors::SaveOnlineTestError.new(I18n.t("online_tests.messages.error.save_failed")) unless target_mot.save

        #录入得分点
        Mongodb::MobileUserQizpointScore.save_score params

        #分析成绩
        pupil = wx_current_user.nil?? nil : wx_current_user.pupil
        mobile_report_generator = Mongodb::MobileUserReportGenerator.new({
        	:pap_uid => params[:paper][:pap_uid],
            :pup_uid => pupil.nil?? "" : pupil.uid,
            :wx_openid => params[:wx_openid]
        })
        
        mobile_report_generator.cal_ckp_total_avg
        mobile_report_generator.add_avg_col
        mobile_report_generator.cal_based_on_total_avg
        mobile_report_generator.construct_rank
        mobile_report_generator.construct_ckp_charts
        mobile_report_generator.construct_weak_ckps
        mobile_report_generator.construct_knowledge_weak_ckps

        result = response_json(200, {message: I18n.t("wx_scores.messages.error.save_success")})
      rescue Exception => ex
        result = response_json(500, {message: I18n.t("wx_scores.messages.error.save_exception")})
      end
    end

    render :json => result
  end
end
