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
        paper_json = JSON.parse(current_paper.paper_json)
        result = response_json(200, {paper_json: paper_json})
      else
        result = response_json(400, {message: I18n.t("wx_papers.messages.info.no_paper")})
      end
    end

  	render :json => result
  end
end
