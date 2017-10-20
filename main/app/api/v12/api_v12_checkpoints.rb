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
        authenticate_api_permission current_user.id, request.request_method, request.fullpath
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

      desc '根据相关信息获取内容'
      params do
        requires :grade, type: String
        optional :quiz_uid, type: String
        requires :subject, type: String
        requires :knowledge_uid, type: String 
        requires :accuracy, type: String, values: ["exact", "normal"]
        requires :levelword, type: String
        optional :cat_type, type: String
        given accuracy: ->(val) { val == 'exact' } do
        end
        given accuracy: ->(val) {val == 'normal'} do
          optional :ability_uid, type: String
          optional :skill_uid, type: String
          mutually_exclusive :ability_uid, :skill_uid
        end
      end
      post :get_related_quizs_plus do
        result, flag = BankSubjectCheckpointCkp.get_related_quizs params.deep_stringify_keys
        if flag
           result
        else
          error!(message_json(result), 404)
        end
      end
    end
  end
end
