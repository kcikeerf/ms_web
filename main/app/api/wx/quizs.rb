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
        authenticate!
      end

      #
      desc ''
      params do
        use :authenticate
        requires :test_id, type: String, allow_blank: false
        requires :pupil_user_name, type: String, allow_blank: false
        optional :qzp_id, type: String, allow_blank: true
        optional :qzp_order, type: String, allow_blank: true
        exactly_one_of :qzp_id, :qzp_order
      end
      post :detail do
        target_user = User.where(name: params[:pupil_user_name]).first
        error!(message_json("w21204"), 403) if target_user.blank? || !target_user.is_pupil?
        unless params[:qzp_id].blank?
          redis_key = "/api/quizs/test/#{params[:test_id]}/user/#{target_user.id}/qzp_id/#{params[:qzp_id]}"
        else
          redis_key = "/api/quizs/test/#{params[:test_id]}/user/#{target_user.id}/qzp_order/#{params[:qzp_order]}"
        end

        if Common::SwtkRedis::has_key? Common::SwtkRedis::Ns::Cache, redis_key
          result = Common::SwtkRedis::get_value Common::SwtkRedis::Ns::Cache, redis_key
          JSON.parse(result)
        else
          target_test = Mongodb::BankTest.where(_id: params[:test_id]).first
          target_paper = target_test.bank_paper_pap
          target_qzps = target_paper.bank_quiz_qizs.map{|qiz| qiz.bank_qizpoint_qzps}.flatten.sort{|a,b| Common::Locale.mysort(a.order.gsub(/(\(|\))/,"").ljust(5,"0"),b.order.gsub(/(\(|\))/,"").ljust(5,"0")) }
          target_qzp_order_arr = target_qzps.map{|item| item.order.gsub(/(\(|\))/,"").ljust(5,"0")}
          unless params[:qzp_id].blank?
            target_qzp = Mongodb::BankQizpointQzp.where(_id: params[:qzp_id]).first
          else #为了兼容旧记录
            qzp_index = params[:qzp_order].to_i - 1
            error!(message_json("e40004"), 404) if qzp_index < 0
            target_qzp = target_qzps[qzp_index]
          end
          target_quiz = target_qzp.bank_quiz_qiz
          error!(message_json("e40004"), 404) unless target_qzp
          target_qzp_order_str = (target_qzp && !target_qzp.order.blank? )? target_qzp.order.gsub(/(\(|\))/,"") : nil
          order_index = target_qzp_order_arr.find_index(target_qzp_order_str.ljust(5,"0"))
          error!(message_json("e40004"), 404) unless order_index
          target_qzp_order = (order_index + 1).to_s

          # 临时添加
          hyt_quiz_data_h = {}
          hyt_snapshot_data_h = {}
          begin
            Find.find("/reports_warehouse/tests/#{params[:test_id]}"){|f|
              # quiz data
              hyt_quiz_data_re = Regexp.new ".*pupil/#{target_user.role_obj.uid}_hyt_quiz_data.json"
              r = hyt_quiz_data_re.match(f)
              unless r.blank?
                data = File.open(f, 'rb').read
                hyt_quiz_data_h = JSON.parse(data)
              end
              # snapshot data
              hyt_snapshot_data_re = Regexp.new ".*pupil/#{target_user.role_obj.uid}_hyt_snapshot_data.json"
              r = hyt_snapshot_data_re.match(f)
              unless r.blank?
                data = File.open(f, 'rb').read
                hyt_snapshot_data_h = JSON.parse(data)
              end          
            }
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