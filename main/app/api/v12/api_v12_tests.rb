# -*- coding: UTF-8 -*-

module ApiV12Tests
  class API < Grape::API
    format :json

    helpers Doorkeeper::Grape::Helpers
    helpers ApiV12Helper
    helpers ApiV12SharedParamsHelper


    helpers do
      def get_pupil_report_data report_path
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
          # Common::SwtkRedis::set_key Common::SwtkRedis::Ns::Cache, report_path, report_data.to_json
        end
        return report_data
      end

      def sort_quiz_with_answer paper_qzps
        mistakes_list = []
        corectly_list = []
        paper_qzps.each {|qzp| 
          taget_qzp = Mongodb::BankQizpointQzp.where(_id: qzp["qzp_id"]).first
          if (qzp["value"]["total_full_score"] != qzp["value"]["total_real_score"])
            mistakes_list << taget_qzp.bank_quiz_qiz_id.to_s
          else
            corectly_list << taget_qzp.bank_quiz_qiz_id.to_s
          end
        }
        return mistakes_list, corectly_list
      end


    end

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

      #获取某个指标的试题
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
              data =  get_pupil_report_data params[:report_url]
              result["paper_qzps"] = data["paper_qzps"]
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

      desc "student error quiz list"
      params do
        requires :report_url, type: String
      end
      post :get_error_quiz_list do        
        data = get_pupil_report_data params[:report_url]
        paper_qzps = data["paper_qzps"]
        paper_qzps = paper_qzps.select {|qzp| 
          qzp if qzp &&  (qzp["value"]["total_full_score"] != qzp["value"]["total_real_score"])
        }
        paper_qzps
      end

      # desc "获取学生的习题列表"
      # params do
      #   requires :test_uid, type: String
      # end
      # post :get_stu_quiz_list do
      #   loc = "/Users/shuai/workspace/tk_main/main" 
      #   path = "/reports_warehouse/tests/"
      #   user_uid = current_user.role_obj.uid
      #   file_path = Dir[loc + path + params[:test_uid] + "/project/" + params[:test_uid] + "/**/" + user_uid + ".json"]
      #   if file_path.size > 0
      #     paper_qzps = get_pupil_report_data file_path.first
      #     m_list, c_list = sort_quiz_with_answer paper_qzps

      #     # mistakes_list = []
      #     # corectly_list = []
      #     # mistakes_list << m_list
      #     # corectly_list << c_list
      #     # mistakes_list.flatten!
      #     # corectly_list.flatten!

      #   else

      #   end
      # end

      desc "download_able_list"
      params do
      end
      post :download_able_list do
        user = current_user
        if user.children.size > 0

          children = user.children
          pupil_users = []
          children.each {|c| 
            pupil_users << c if c.is_pupil?
          }
          if pupil_users.size > 0
            test_list = []
            pupil_users.each { |u|
              # pupil = u.role_obj
              bank_tests = u.bank_tests
              bank_tests.each {|b_test|
                _rpt_type, _rpt_id = Common::Uzer::get_user_report_type_and_id_by_role(u)
                rpt_type = _rpt_type || Common::Report::Group::Project
                rpt_id = (_rpt_type == Common::Report::Group::Project)? b_test._id.to_s : _rpt_id
                report_url = Common::Report::get_test_report_url(b_test._id.to_s, rpt_type, rpt_id)
                if bank_test.quiz_type == "xy_default"
                  if report_url.present?
                    target_pap = bank_test.bank_paper_pap
                    if target_pap.present?
                      test_list << {
                        uid: b_test._id.to_s,
                        name: b_test.name,
                        report_url: report_url,
                        subject: target_pap.subject,
                        subject_cn: Common::Locale::i18n("dict.#{target_pap.subject}")
                      }
                    end
                  end
                end
              }
            }
            success_message_json("i00000",{test_list: test_list.uniq})
          else
            message_json("e44404",404)
          end
        else
          message_json("e44404",500)
        end
      end

      desc "获取学生的错题列表"
      params do
        requires :report_url_list, type: Array 
      end
      post :incorrect_item do
        begin         
          time_day = Time.now.strftime('%Y/%m/%d')  
          # base = "/Users/shuai/workspace/tk_main/main"
          mistakes_list = []
          incorrect_info = {}
          params[:report_url_list].each {|_url|
            # data = get_pupil_report_data (base+_url) #本地获取
            data = get_pupil_report_data _url #服务器方式
            if data["paper_qzps"].present?            
              incorrect_info["basic"] = data["basic"] 
              m_list, c_list = sort_quiz_with_answer data["paper_qzps"]
              mistakes_list << m_list
              # corectly_list << c_list
            end
          }
          incorrect_item = []
          mistakes_list.flatten!
          mistakes_list.each {|quiz_uid|
            quiz = Mongodb::BankQuizQiz.where(_id: quiz_uid).first
            if quiz.present?
              incorrect_item << quiz.exercise
            end
          }
          if incorrect_item.present?
            incorrect_item = incorrect_item.sort { |x,y| y["quiz_cat"] <=> x["quiz_cat"] }
          end
          incorrect_info["incorrect_item"] = incorrect_item
          # corectly_list.flatten!
          success_message_json("i00000",{collection: incorrect_info})
        rescue Exception => e
          Rails.logger.info e.backtrace.inspect
          message_json("e50000",500)
        end
      end
    end
  end
end