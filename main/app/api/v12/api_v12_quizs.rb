# -*- coding: UTF-8 -*-
require 'find'

module ApiV12Quizs
  class API < Grape::API
    format :json

    helpers Doorkeeper::Grape::Helpers
    helpers ApiV12Helper
    helpers ApiV12SharedParamsHelper

    params do
      use :oauth
    end

    resource :quizs do
      before do
        set_api_header
        doorkeeper_authorize!
        authenticate_api_permission current_user.id, request.request_method, request.fullpath
      end

      #
      desc ''
      params do
        optional :test_id, type: String, allow_blank: true
        optional :pupil_user_name, type: String, allow_blank: false
        requires :qzp_id, type: String, allow_blank: true
        # optional :qzp_order, type: String, allow_blank: true
        # exactly_one_of :qzp_id, :qzp_order
      end
      post :detail do
        target_current_user = current_user
        target_pupil = target_current_user.is_pupil?? target_current_user : User.where(name: params[:pupil_user_name]).first
        redis_user_id = target_pupil.blank?? target_current_user.id : target_pupil.id
        redis_key = "/api/quizs/test/#{params[:test_id]}/user/#{redis_user_id}/qzp_id/#{params[:qzp_id]}"
        begin         
          if Common::SwtkRedis::has_key? Common::SwtkRedis::Ns::Cache, redis_key
            result = Common::SwtkRedis::get_value Common::SwtkRedis::Ns::Cache, redis_key
            JSON.parse(result)
          else
            target_test = Mongodb::BankTest.where(_id: params[:test_id]).first
            error!(message_json("e40004"), 404) unless target_test

            target_qzp = Mongodb::BankQizpointQzp.where(_id: params[:qzp_id]).first
            error!(message_json("e40004"), 404) unless target_qzp
            target_qzp_asc_order = target_qzp.asc_order
            target_quiz = target_qzp.bank_quiz_qiz
            error!(message_json("e40004"), 404) unless target_quiz

            # 临时添加
            if !target_pupil.blank?
              hyt_quiz_data_h = {}
              hyt_snapshot_data_h = {}
              begin
                hyt_quiz_data_f = Dir[Common::Report::WareHouse::ReportLocation + "reports_warehouse/tests/" + params[:test_id]+ '/**/pupil/' + target_pupil.role_obj.uid + '_hyt_quiz_data.json'].first.to_s
                hyt_quiz_data = File.open(hyt_quiz_data_f, 'rb').read
                hyt_quiz_data_h = JSON.parse(hyt_quiz_data) if !hyt_quiz_data.blank?

                hyt_snapshot_data_f = Dir[Common::Report::WareHouse::ReportLocation + "reports_warehouse/tests/" + params[:test_id]+ '/**/pupil/' + target_pupil.role_obj.uid + '_hyt_snapshot_data.json'].first.to_s
                hyt_snapshot_data = File.open(hyt_snapshot_data_f, 'rb').read
                hyt_snapshot_data_h = JSON.parse(hyt_snapshot_data) if !hyt_snapshot_data.blank?
              rescue Exception => ex
                # do nothing
              end

              hyt_quiz_data = {}
              hyt_snapshot_data = {}
              target_hyt_quiz = hyt_quiz_data_h.find{|item| item["qzp_order"] == target_qzp_asc_order}
              if target_hyt_quiz.blank?
                target_hyt_quiz = hyt_snapshot_data_h.find{|item| item["qzp_order"] == target_qzp_asc_order}
                hyt_snapshot_data = { target_hyt_quiz["qzp_order"].to_sym => target_hyt_quiz["image_url"] } unless target_hyt_quiz.blank?
              else
                hyt_quiz_data = { target_hyt_quiz["qzp_order"].to_sym => target_hyt_quiz["answer"] }
              end
            else
              hyt_quiz_data = {}
              hyt_snapshot_data = {} 
            end
            ###

            result = {
              :id => target_qzp.id.to_s,
              :quiz_cat => target_quiz.cat,
              :quiz_body => target_quiz.text,
              :quiz_uid => target_quiz._id.to_s,
              :qzp_order => target_qzp.order,
              :qzp_asc_order => target_qzp_asc_order,
              :qzp_custom_order => target_qzp.custom_order,
              :qzp_type => Common::Locale::hanzi2pinyin(target_qzp.type),
              :full_score => target_qzp.score,
              :qzp_answer => target_qzp.answer,
              :levelword => target_quiz.levelword2,
              :qzp_analysis => nil,
              :result_info => {
                  :result_url => nil,
                  :result_answer => nil,
                  # 临时添加
                  :hyt_quiz_data => hyt_quiz_data,
                  :hyt_snapshot_data => hyt_snapshot_data
                  #
              },
              :lv2_ckp => target_qzp.lv2_checkpoint,
              :end_ckp => target_qzp.end_checkpoint,
              # 预留，指标信息
              :indices => {},
              # 预留，学习资料信息
              :learning_materials => {},
              # 预留，针对性试题解析
              :analysis => {},
              # 预留，指导性信息
              :guide => {},
              # 预留
              :others => {}
            }

            Common::SwtkRedis::set_key Common::SwtkRedis::Ns::Cache, redis_key, result.to_json
            result
          end     
        rescue Exception => e
          error!({code: "e40003", message: I18n.t("api.#{'e40003'}", message: e.message)}, 500)
        end
      end

    end

  end # api
end # module