# -*- coding: UTF-8 -*-

module ApiV12OnlineTests
  class API < Grape::API
    format :json

    helpers ApiV12Helper
    helpers ApiV12SharedParamsHelper
    helpers Doorkeeper::Grape::Helpers

    params do
      use :oauth
    end

    
    resource :online_tests do

      before do
        set_api_header
        doorkeeper_authorize!
      end

      ###########

      desc '获取综合测试列表 post /api/v1.2/online_tests/zh_list'
      params do
        requires :test_id, type: String, allow_blank: false
      end
      post :zh_todo_list do
        pub_tests = Mongodb::BankTest.by_public(true)
        priv_tests = Mongodb::BankTestUserLink.by_user(current_user.id).lt_times(1).map{|item| item.bank_test}
        {
          :public => pub_tests.map{|item|
            {
              :name => item.name,
              :quiz_type => item.quiz_type,
              :quiz_type_label => Common::Test::Type[item.quiz_type.to_sym],
              :ext_data_path => item.ext_data_path
            }
          },
          :private => priv_tests.map{|item|
            {
              :name => item.name,
              :quiz_type => item.quiz_type,
              :quiz_type_label => Common::Test::Type[item.quiz_type.to_sym],
              :ext_data_path => item.ext_data_path,
              :start_date => item.start_date,
              :end_date => item.end_date
            }
          }
        }
      end

      ###########

      desc '获取已测试过综合列表 post /api/v1.2/online_tests/zh_result'
      params do
        requires :test_id, type: String, allow_blank: false
      end
      post :zh_tested_list do
        target_tests = Mongodb::BankTestUserLink.by_user(current_user.id).gte_times(1).map{|item| item.bank_test}
        target_tests.map{|item|
          {
            :name => item.name,
            :quiz_type => item.quiz_type,
            :quiz_type_label => Common::Test::Type[item.quiz_type.to_sym],
            :ext_data_path => item.ext_data_path,
            :start_date => item.start_date,
            :end_date => item.end_date,
            :report_url => target_url
          }
        }
      end

      ###########

      desc '提交综合测试结果 post /api/v1.2/online_tests/zh_result'
      params do
        requires :test_id, type: String, allow_blank: false
      end
      post :zh_result do
        target_test = Mongodb::BankTest.where(id: params[:test_id]).first
        if target_test
          # 结果保存
          Common::ReportPlus2::online_test_import_results params[:test_id], current_user.id, params, {:user_model => "WxUser", :wx_openid => params[:wx_openid]}
          
          if target_test.is_public
            rpt_params = {
              :user_token => current_user.tk_token,
              :group_type => Common::Report2::Group::Individual
            }
          else
            rpt_params = {
              :pup_uid => current_user.pupil.uid,
              :group_type => Common::Report2::Group::Pupil
            }
          end
          rpt_params[:test_id] = params[:test_id]

          # 个人报告生成
          # 1) 定义变量 
          individual_generator = Mongodb::OnlineTestZhFzqnIndividualGenerator.new(rpt_params)
          individual_constructor = Mongodb::OnlineTestZhFzqnGroupConstructor.new(rpt_params)
          # 2) 个人报告生成
          individual_generator.clear_old_data
          individual_generator.cal_round_1
          individual_generator.cal_round_2
          # 3)个人报告组装
          individual_constructor.construct_round_1
          individual_constructor.pre_owari
          individual_constructor.owari

          {
            message: message_json("i12001")
          }
        else
          status 404
          { 
            message: Common::Locale::i18n("swtk_errors.object_not_found", :message => "Test not existed!" ) 
          }
        end
      end

      ###########

      desc '随机获取任一试卷 post /api/v1.2/online_tests/sample'
      params do
        requires :grade, type: String, allow_blank: false
        requires :term, type: String, allow_blank: false
        requires :subject, type: String, allow_blank: false
      end
      post :sample do
        params_h ={
          :can_online_test => nil,
          :grade => params[:grade],
          :term => params[:term],
          :subject => params[:subject]
        }
        target_pap = Mongodb::BankPaperPap.get_a_paper params_h
        # current_paper = Mongodb::BankPaperPap.where(_id: "578c8579980146652f56a3a8").first || Mongodb::BankPaperPap.get_a_paper(params_h)
        if target_pap
          paper_h = JSON.parse(target_pap.paper_json)
          ############################
          # 临时处理，待流程整理后处理
          paper_h["paper_html"] = ""
          paper_h["answer_html"] = ""
          paper_h["paper"]= ""
          ############################
          status = 200
          data = {
            #online_test_id: xxxx, #未来实现
            pap_uid: target_pap.id.to_s,
            paper_json: paper_h.to_json, 
            message: Common::Locale::i18n("wx_papers.messages.info.get_success")
          }
        else
          status 404
          { 
            message: Common::Locale::i18n("swtk_errors.object_not_found", :message => request.params.to_json ) 
          }
        end
      end

      ###########

      desc '获取测试列表 post /api/v1.2/online_tests/list'
      params do
        requires :wx_openid, type: String, allow_blank: false
      end
      post :list do
        result = []
        target_test_user_links = Mongodb::OnlineTestUserLink.by_wx_user(current_wx_user.id)
        target_test_user_links.each{|item|
          online_test = Mongodb::OnlineTest.where(id: item.online_test_id).first
          next unless online_test
          target_pap = online_test.bank_paper_pap
          next unless target_pap
          target_pap_h = JSON.parse(target_pap.paper_json)
          result << {
            :online_test_id => item.online_test_id,
            :last_update => item.dt_update.strftime('%Y-%m-%d'),
            :paper_information => target_pap_h["information"]
          }
        }
        result
      end

      ########### 

      desc '上传测试成绩 post /api/v1.2/online_tests/submit'
      params do
        requires :wx_openid, type: String, allow_blank: false
        requires :pap_uid, type: String, allow_blank: false
        requires :bank_quiz_qizs, type: Array, allow_blank: false
        #optional :online_test_id, type: String, allow_blank: true
      end
      post  :submit do
        # 查找测试
        target_test_user_link = get_online_test_user_link
        if target_test_user_link && 
           [ Common::OnrineTest::Status::ScoreImporting, 
             Common::OnrineTest::Status::report_generating 
           ].include?(target_test_user_link.target_test_status)
          error!(message_json("e43002"), 403)
        else
          # 创建跟踪Task，Job
          target_task = TaskList.new({
            :name => "submitting online test results",
            :task_type => Common::Task::Type::SubmittingOnlineTestResult,
            :status => Common::Task::Status::InActive
          })
          target_task.save!
          job_tracker = JobList.new({
            :name => "submitting online test results",
            :task_uid => target_task.uid,
            :status => Common::Job::Status::NotInQueue,
            :process => 0
          })
          job_tracker.save!
        end

        # backend job
        Thread.new do
          GenerateOnlineTestReportsJob.perform_later({
            # :online_test_id => params[:online_test_id],#未来实现
            :task_uid => target_task.uid,
            :wx_user_id => current_wx_user.uid,
            :pap_uid => params[:pap_uid],
            :results => params[:bank_quiz_qizs]
          })
        end

        status 200
        message_json("i13001").merge({
          :task_uid => target_task.uid
        })
      end

    end # resource online test
  end # class
end # module