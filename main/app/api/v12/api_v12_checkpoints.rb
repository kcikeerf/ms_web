# -*- coding: UTF-8 -*-

module ApiV12Checkpoints
  class API < Grape::API
    format :json

    helpers Doorkeeper::Grape::Helpers
    helpers ApiV12Helper
    helpers ApiV12SharedParamsHelper

    params do
      use :oauth
    end

    resource :checkpoints do #checkpoints begin
      before do
        set_api_header
        doorkeeper_authorize!
      end
      
      desc '随机获取相关指标的单题' # grade_class_list begin
      params do
        requires :ckp_uid, type: String
        optional :amount, type: Integer, allow_blank: true
      end

      post :get_related_quizs do
        checkpoint = BankSubjectCheckpointCkp.where(uid: params[:ckp_uid]).first
        if checkpoint
          checkpoint.get_related_quizs params
        else
          error!(message_json("w25000"), 404)
        end
      end

    end
  end
end
