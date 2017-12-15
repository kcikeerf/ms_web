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
          Common::SwtkRedis::set_key Common::SwtkRedis::Ns::Cache, report_path, report_data.to_json
        end
        bank_test_uid = report_path.split("reports_warehouse/tests")[1].split("/")[1]
        unless Common::SwtkRedis::has_key? Common::SwtkRedis::Ns::Cache, "/cache/bank_test_name/" + bank_test_uid
          bank_test = Mongodb::BankTest.where(_id: bank_test_uid).first
          if bank_test.present?
            Common::SwtkRedis::set_key Common::SwtkRedis::Ns::Cache, "/cache/bank_test_name/" + bank_test_uid, [bank_test.name, bank_test.quiz_date.strftime('%Y-%m-%d')]
          end
        end
        return bank_test_uid, report_data
      end

      def sort_quiz_with_answer paper_qzps, bank_test_uid
        mistakes_list = []
        corectly_list = []
        paper_qzps.each {|qzp| 
          taget_qzp = Mongodb::BankQizpointQzp.where(_id: qzp["qzp_id"]).first
          if qzp["value"].present?
            if (qzp["value"]["total_full_score"] != qzp["value"]["total_real_score"])
              mistakes_list << [taget_qzp.bank_quiz_qiz_id.to_s,bank_test_uid] if taget_qzp.present?
            else
              corectly_list << [taget_qzp.bank_quiz_qiz_id.to_s,bank_test_uid] if taget_qzp.present?
            end
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

      desc "创建测试"
      params do
        requires :name, type: String
        requires :start_date, type: String
        requires :quiz_date, type: String
        requires :paper_uid, type: String
        requires :test_type, type: String
        requires :id, type: String
      end
      post :create_test do
        current_test = Mongodb::BankTest.new

        begin
          params[:user_id] = current_user.id
          current_test.save_test params
        rescue Exception => ex
          error!(message_json_data("e50000",{error_message: ex.message}),500)
        end

      end

      desc "学校状态回退"
      params do
        requires :test_uid, type: String
        requires :tenant_uid, type: String 
      end
      get :rollback_tenant do
        begin
          bank_test = Mongodb::BankTest.where(id: params[:test_uid]).first
          bank_test.rollback_tenant params[:tenant_uid]
        rescue Exception => ex
          error!(message_json_data("e50000",{error_message: ex.message}),500)
        end
      end

      desc "忽略该学校"
      params do
        requires :test_uid, type: String
        requires :tenant_uid, type: String 
      end
      get :ignore_tenant do
        begin
          bank_test = Mongodb::BankTest.where(id: params[:test_uid]).first
          bank_test.ignore_tenant params[:tenant_uid]
        rescue Exception => ex
          error!(message_json_data("e50000",{error_message: ex.message}),500)
        end
      end

      desc "获取当前用户已经三维解析完成的试卷"
      params do
      end
      get :get_pap do
        papers = Mongodb::BankPaperPap.get_list_api current_user.id
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

      desc '上传学业报告的成绩'
      params do
        # requires :test_id, type: String, allow_blank: false
        requires :basic, type: Hash do
          requires :test_id, type: String
          requires :pap_uid, type: String
          requires :province, type: String
          requires :province_id, type: String
          requires :city, type: String
          requires :city_id, type: String
          requires :district, type: String
          requires :district_id, type: String
          requires :tenant, type: String
          requires :tenant_uid, type: String
          requires :grade, type: String
          requires :grade_uid, type: String
          requires :klass, type: String
          requires :klass_uid, type: String
          requires :name, type: String
          requires :id, type: String
          requires :gender, type: String
          requires :student_number, type: String
        end
        optional :result, type: Array do 
          requires :qzp_uid, type: String
          requires :order, type: Integer
          requires :full_score, type: String
          requires :real_score, type: String
        end
      end
      post :rc_import_results do
        begin
          bank_test = Mongodb::BankTest.where(_id: params[:basic][:test_id]).first
          if bank_test.present?
            rc_test_user_house = Mongodb::RcTestUserHouse.new()
            rc_test_user_house.save_ins params[:basic].to_hash.deep_symbolize_keys
            Mongodb::BankTestScore.save_all_qzp(params[:result], rc_test_user_house._id)
            message_json("i00000")
          else
            error!(message_json_data("e40000",{error_message: "测试不存在"}),404)
          end
        rescue Exception => ex
          error!(message_json_data("e40000",{error_message: ex.message}),500)
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
        if bank_test.present?
          paper = bank_test.bank_paper_pap
          if paper
            result = paper.get_ckp_quiz params
            if params[:report_url]
              _test, data =  get_pupil_report_data params[:report_url]
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
        _test, data = get_pupil_report_data params[:report_url]
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
        if user.is_pupil?
          test_list = []
          bank_tests = user.bank_tests
          bank_tests.each {|b_test|
            _rpt_type, _rpt_id = Common::Uzer::get_user_report_type_and_id_by_role(user)
            rpt_type = _rpt_type || Common::Report::Group::Project
            rpt_id = (_rpt_type == Common::Report::Group::Project)? b_test._id.to_s : _rpt_id
            report_url = Common::Report::get_test_report_url(b_test._id.to_s, rpt_type, rpt_id)
            if b_test.quiz_type == "xy_default"
              if report_url.present?
                target_pap = b_test.bank_paper_pap
                if target_pap.present?
                  test_list << {
                    uid: b_test._id.to_s,
                    name: b_test.name,
                    report_url: report_url,
                    subject: target_pap.subject,
                    subject_cn: Common::Locale::i18n("dict.#{target_pap.subject}"),
                    user_name: user.role_obj.present? ? user.role_obj.name : "--"
                  }
                end
              end
            end
          }
          message_json_data("i00000",{test_list: test_list.uniq})
        else
          error!(message_json("e44404"),404)
        end
      end

      desc "获取学生的错题列表"
      params do
        requires :report_url_list, type: Array 
      end
      post :incorrect_item do
        begin
          not_included_quiz = %W{shu_mian_biao_da xie_zuo}
          time_day = Time.now.strftime('%Y/%m/%d')  
          # base = "/Users/shuai/workspace/tk_main/main"
          mistakes_list = []
          incorrect_info = {}
          params[:report_url_list].to_a.each_with_index {|_url, index|
            _url = _url.split("?")[0]
            # _test, data = get_pupil_report_data (base+_url) #本地获取
            _test, data = get_pupil_report_data _url #服务器方式
            if data["paper_qzps"].present?
              incorrect_info["basic"] = data["basic"] 
              m_list, c_list = sort_quiz_with_answer data["paper_qzps"], _test
              mistakes_list << m_list
              # corectly_list << c_list
            end
          }
          incorrect_item = []
          mistakes_list = mistakes_list.uniq.flatten(1)
          mistakes_list.each_with_index {|quiz_bank_uids, index|
            quiz = Mongodb::BankQuizQiz.where(_id: quiz_bank_uids[0]).first
            if quiz.present?
              quiz_body =  quiz.exercise
              if quiz_body.present? && !not_included_quiz.include?(quiz_body["quiz_cat"])
                if Common::SwtkRedis::has_key? Common::SwtkRedis::Ns::Cache, "/cache/bank_test_name/" + quiz_bank_uids[1]
                  # quiz_body["test_name"] = bank_test.name
                  test_info = Common::SwtkRedis::get_value Common::SwtkRedis::Ns::Cache, "/cache/bank_test_name/" + quiz_bank_uids[1]
                  test_info = eval(test_info)
                  quiz_body["bank_test_name"] = test_info[0]
                  quiz_body["bank_test_time"] = test_info[1]
                else
                  quiz_body["bank_test_name"] = "由于时间太久，暂时不确定试题时哪次测试中的错题"
                  quiz_body["bank_test_time"] = "-"
                end
                incorrect_item << quiz_body
              end
            end
          }
          if incorrect_item.present?
            incorrect_item = incorrect_item.uniq.sort { |x,y| Common::Paper::QuizTypeKey[x["subject"].to_sym].index(x["quiz_cat"]) <=> Common::Paper::QuizTypeKey[y["subject"].to_sym].index(y["quiz_cat"]) }
          end
          incorrect_info["incorrect_item"] = incorrect_item
          # corectly_list.flatten!
          message_json_data("i00000",{collection: incorrect_info})
        rescue Exception => e
          Rails.logger.info e.backtrace.inspect
          error!(message_json("e50000"),500)
        end
      end
    end
  end
end