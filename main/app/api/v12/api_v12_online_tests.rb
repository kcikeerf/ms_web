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

      ####### Group: 需要验证Token, begin #######
      group do 
        before do
          set_api_header
          doorkeeper_authorize!
        end

        ###########

        desc '随机获取任一试卷 get /api/v1.2/online_tests/sample'
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

        desc '获取测试列表 get /api/v1.2/online_tests/list'
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
      end
      ####### Group: 需要验证Token, end #######

      ####### Group: 不需要验证Token, begin #######
      group do # 不需要验证Token
        before do
          set_api_header
        end

        ###########

        desc '获取公开的测试列表'
        params do
          #
        end
        post :public_list do
        end

        ###########

        desc '获取项目的测试列表'
        params do
          #
        end
        post :project_list do
        end

      end
      ####### Group: 不需要验证Token, begin #######

    end # resource online test
  end # class
end # module