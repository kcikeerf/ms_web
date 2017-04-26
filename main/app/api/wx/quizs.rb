# -*- coding: UTF-8 -*-
require 'find'

module Quizs
  class API < Grape::API
    version 'v1.1', using: :path #/api/v1/<resource>/<action>
    format :json
    prefix "api/wx".to_sym

    helpers ApiHelper
    helpers SharedParamsHelper

    resource :quizs do
      before do
        set_api_header
        #authenticate!
      end

      #
      desc ''
      params do
        use :authenticate
        requires :test_id, type: String, allow_blank: false
        optional :pupil_user_name, type: String, allow_blank: false
        requires :qzp_id, type: String, allow_blank: true
        # optional :qzp_order, type: String, allow_blank: true
        # exactly_one_of :qzp_id, :qzp_order
      end
      post :detail do
        target_current_user = current_user
        target_pupil = target_current_user.is_pupil?? target_current_user : User.where(name: params[:pupil_user_name]).first
        #error!(message_json("w21204"), 403) if target_user.blank?
        redis_user_id = target_pupil.blank?? target_current_user.id : target_pupil.id
        redis_key = "/api/quizs/test/#{params[:test_id]}/user/#{redis_user_id}/qzp_id/#{params[:qzp_id]}"
        # unless params[:qzp_id].blank?
        #   redis_key = "/api/quizs/test/#{params[:test_id]}/user/#{redis_user_id}/qzp_id/#{params[:qzp_id]}"
        # else
        #   redis_key = "/api/quizs/test/#{params[:test_id]}/user/#{redis_user_id}/qzp_order/#{params[:qzp_order]}"
        # end

        if Common::SwtkRedis::has_key? Common::SwtkRedis::Ns::Cache, redis_key
          result = Common::SwtkRedis::get_value Common::SwtkRedis::Ns::Cache, redis_key
          JSON.parse(result)
        else
          target_test = Mongodb::BankTest.where(_id: params[:test_id]).first
          error!(message_json("e40004"), 404) unless target_test
          target_paper = target_test.bank_paper_pap
          error!(message_json("e40004"), 404) unless target_paper

          order_redis_key = "/api/papers/" + target_paper.id.to_s + "/qzps_orders/"
          if Common::SwtkRedis::has_key? Common::SwtkRedis::Ns::Cache, order_redis_key
            target_qzp_order_arr = $cache_redis.lrange(order_redis_key, 0, -1)
          else
            target_qzps = target_paper.ordered_qzps
            target_qzp_order_arr = target_qzps.map(&:order)
            $cache_redis.rpush(order_redis_key, target_qzp_order_arr)
          end

          unless params[:qzp_id].blank?
            target_qzp = Mongodb::BankQizpointQzp.where(_id: params[:qzp_id]).first
          end
          target_quiz = target_qzp.bank_quiz_qiz
          error!(message_json("e40004"), 404) unless target_qzp
          target_qzp_order_str = (target_qzp && !target_qzp.order.blank? )? target_qzp.order : nil
          order_index = target_qzp_order_arr.find_index(target_qzp_order_str)
          error!(message_json("e40004"), 404) unless order_index
          target_qzp_order = (order_index + 1).to_s

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
            target_hyt_quiz = hyt_quiz_data_h.find{|item| item["qzp_order"] == target_qzp_order}
            if target_hyt_quiz.blank?
              target_hyt_quiz = hyt_snapshot_data_h.find{|item| item["qzp_order"] == target_qzp_order}
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
            :qzp_order => target_qzp_order,
            :qzp_type => Common::Locale::hanzi2pinyin(target_qzp.type),
            :full_score => target_qzp.score,
            :qzp_answer => target_qzp.answer,
            :qzp_analysis => nil,
            :result_info => {
                :result_url => nil,
                :result_answer => nil,
                # 临时添加
                :hyt_quiz_data => hyt_quiz_data,
                :hyt_snapshot_data => hyt_snapshot_data
                #
            },
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
      end

    end

   end # api
end # module