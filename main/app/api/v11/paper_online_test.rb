# -*- coding: UTF-8 -*-

module PaperOnlineTest
  class API < Grape::API
    version 'v1.1', using: :path #/api/v1/<resource>/<action>
    format :json
    prefix "api/wx".to_sym

    helpers ApiHelper
    helpers SharedParamsHelper

    params do
      use :authenticate
    end
    resource :online_tests do

      # before do
      #   set_api_header
      #   authenticate!
      # end

      # ###########

      # desc '随机获取任一试卷 get /api/wx/v1.1/online_tests/sample'
      # params do
      #   requires :grade, type: String, allow_blank: false
      #   requires :term, type: String, allow_blank: false
      #   requires :subject, type: String, allow_blank: false
      # end
      # post :sample do
      #   params_h ={
      #     :can_online_test => nil,
      #     :grade => params[:grade],
      #     :term => params[:term],
      #     :subject => params[:subject]
      #   }
      #   target_pap = Mongodb::BankPaperPap.get_a_paper params_h
      #   # current_paper = Mongodb::BankPaperPap.where(_id: "578c8579980146652f56a3a8").first || Mongodb::BankPaperPap.get_a_paper(params_h)
      #   if target_pap
      #     paper_h = JSON.parse(target_pap.paper_json)
      #     ############################
      #     # 临时处理，待流程整理后处理
      #     paper_h["paper_html"] = ""
      #     paper_h["answer_html"] = ""
      #     paper_h["paper"]= ""
      #     ############################
      #     status = 200
      #     data = {
      #       #online_test_id: xxxx, #未来实现
      #       pap_uid: target_pap.id.to_s,
      #       paper_json: paper_h.to_json, 
      #       message: Common::Locale::i18n("wx_papers.messages.info.get_success")
      #     }
      #   else
      #     status 404
      #     { 
      #       message: Common::Locale::i18n("swtk_errors.object_not_found", :message => request.params.to_json ) 
      #     }
      #   end
      # end

      # ###########

      # desc '获取测试列表 get /api/wx/v1.1/online_tests/list'
      # params do
      #   requires :wx_openid, type: String, allow_blank: false
      # end
      # post :list do
      #   result = []
      #   target_test_user_links = Mongodb::OnlineTestUserLink.by_wx_user(current_wx_user.id)
      #   target_test_user_links.each{|item|
      #     online_test = Mongodb::OnlineTest.where(id: item.online_test_id).first
      #     next unless online_test
      #     target_pap = online_test.bank_paper_pap
      #     next unless target_pap
      #     target_pap_h = JSON.parse(target_pap.paper_json)
      #     result << {
      #       :online_test_id => item.online_test_id,
      #       :last_update => item.dt_update.strftime('%Y-%m-%d'),
      #       :paper_information => target_pap_h["information"]
      #     }
      #   }
      #   result
      # end

      # ###########

      # # desc '获取测试状态 get /api/wx/v1.1/online_tests/check_status'
      # # params do
      # #   requires :online_test_id, type: String, allow_blank: false
      # # end
      # # post :check_status do
      # #   # 查找测试
      # #   target_test_user_link = get_online_test_user_link
      # #   error!(message_json("e40004"), 404) unless target_test_user_link

      # #   # 返回结果      
      # #   status 200
      # #   {
      # #     task_uid: target_test_user_link.task_uid,
      # #     online_test_status: target_test_user_link.online_test_status
      # #   }
      # # end

      # ########### 

      # desc '上传测试成绩 post /api/wx/v1.1/online_tests/submit'
      # params do
      #   requires :wx_openid, type: String, allow_blank: false
      #   requires :pap_uid, type: String, allow_blank: false
      #   requires :bank_quiz_qizs, type: Array, allow_blank: false
      #   #optional :online_test_id, type: String, allow_blank: true
      # end
      # post  :submit do
      #   # 查找测试
      #   target_test_user_link = get_online_test_user_link
      #   if target_test_user_link && 
      #      [ Common::OnrineTest::Status::ScoreImporting, 
      #        Common::OnrineTest::Status::report_generating 
      #      ].include?(target_test_user_link.target_test_status)
      #     error!(message_json("e44002"), 403)
      #   else
      #     # 创建跟踪Task，Job
      #     target_task = TaskList.new({
      #       :name => "submitting online test results",
      #       :task_type => Common::Task::Type::SubmittingOnlineTestResult,
      #       :status => Common::Task::Status::InActive
      #     })
      #     target_task.save!
      #     job_tracker = JobList.new({
      #       :name => "submitting online test results",
      #       :task_uid => target_task.uid,
      #       :status => Common::Job::Status::NotInQueue,
      #       :process => 0
      #     })
      #     job_tracker.save!
      #   end

      #   # backend job
      #   Thread.new do
      #     GenerateOnlineTestReportsJob.perform_later({
      #       # :online_test_id => params[:online_test_id],#未来实现
      #       :task_uid => target_task.uid,
      #       :wx_user_id => current_wx_user.uid,
      #       :pap_uid => params[:pap_uid],
      #       :results => params[:bank_quiz_qizs]
      #     })
      #   end

      #   status 200
      #   message_json("i13001").merge({
      #     :task_uid => target_task.uid
      #   })
      # end

      # ###########

    end
  end
end