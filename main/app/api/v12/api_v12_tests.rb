# -*- coding: UTF-8 -*-

module ApiV12Tests
  class API < Grape::API
    format :json

    helpers Doorkeeper::Grape::Helpers
    helpers ApiV12Helper
    helpers ApiV12SharedParamsHelper

    params do
      use :oauth
    end

    resource :tests do #checkpoints begin
      before do
        set_api_header
        doorkeeper_authorize!
        authenticate_api_permission current_user.id, request.request_method, request.fullpath
      end


      desc '"试卷指标题mapping" post /api/v1.2/tests/paper_ckps_qzps_mapping' # submit_analyze begin
      params do
        requires :test_uid, type: String
      end
      post :paper_ckps_qzps_mapping do
        # authenticate_api_permission current_user.id, "POST" , "/api/v1.2/users/get_binded_users"
        bank_test = Mongodb::BankTest.where(id: params[:test_uid]).first
        if bank_test 
          paper = bank_test.bank_paper_pap
          if paper
            paper.associated_checkpoints
          else
            error!(message_json("e40405"), 404)
          end 
        else
          error!(message_json("e40405"), 404)
        end
      end


      desc "paper_quiz_ckps"
      params do
        requires :test_uid, type: String
        requires :ckp_uid, type: String
        optional :report_url, type: String
      end
      post :paper_quiz_ckps do
        bank_test = Mongodb::BankTest.where(id: params[:test_uid]).first
        if bank_test 
          paper = bank_test.bank_paper_pap
          if paper
            result = paper.get_ckp_quiz params
            if params[:report_url]
            report_path = params[:report_url]
              report_data = {}
              if Common::SwtkRedis::has_key? Common::SwtkRedis::Ns::Cache, report_path
                target_report_j = Common::SwtkRedis::get_value Common::SwtkRedis::Ns::Cache, report_path
                report_data = JSON.parse(target_report_j)
              else
                target_report_f = Dir[report_path].first
                return report_data if target_report_f.blank?
                target_report_data = File.open(target_report_f, 'rb').read
                return report_data if target_report_data.blank?
                report_data = JSON.parse(target_report_data)
                Common::SwtkRedis::set_key Common::SwtkRedis::Ns::Cache, report_path, report_data.to_json
              end
              result["paper_qzps"] = report_data["paper_qzps"]
            end
            if result
              result
            else
              error!(message_json("e40405"), 404)
            end
          else
            error!(message_json("e40405"), 404)
          end 
        else
          error!(message_json("e40405"), 404)
        end
      end

    end
  end
end