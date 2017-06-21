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
        #requires :test_id, type: String, allow_blank: false
      end
      post :todo_list do
        pub_tests = Mongodb::BankTest.by_public(true)
        priv_tests = Mongodb::BankTestUserLink.by_user(current_user.id).lt_times(1).map{|item| item.bank_test}
        {
          :public => pub_tests.map{|item|
            {
              :id => item.id.to_s,
              :name => item.name,
              :quiz_type => item.quiz_type,
              :quiz_type_label => Common::Test::Type[item.quiz_type.to_sym],
              :ext_data_path => item.ext_data_path
            }
          },
          :private => priv_tests.map{|item|
            {
              :id => item.id.to_s,
              :name => item.name,
              :quiz_type => item.quiz_type,
              :quiz_type_label => Common::Test::Type[item.quiz_type.to_sym],
              :ext_data_path => item.ext_data_path,
              :start_date => item.start_date,
              :end_date => item.quiz_date
            }
          }
        }
      end

      ###########

      desc '获取已测试过综合列表 post /api/v1.2/online_tests/zh_result'
      params do
        #requires :test_id, type: String, allow_blank: false
      end
      post :tested_list do
        target_tests = Mongodb::BankTestUserLink.by_user(current_user.id).gte_times(1).map{|item| item.bank_test}
        target_tests.map{|item|
          {
            :id => item.id.to_s,
            :name => item.name,
            :quiz_type => item.quiz_type,
            :quiz_type_label => Common::Test::Type[item.quiz_type.to_sym],
            :ext_data_path => item.ext_data_path,
            :start_date => item.start_date,
            :end_date => item.quiz_date,
            :is_public => item.is_public
          }
        }
      end

      ###########

      desc '提交综合测试结果 post /api/v1.2/online_tests/zh_result'
      params do
        requires :test_id, type: String, allow_blank: false
        requires :result, type: Array, allow_blank: false
        optional :wx_openid, type: String
        optional :wx_unionid, type: String
        at_least_one_of :wx_openid, :wx_unionid        
      end
      post :zh_result do

        tkc = TkJobConnector.new({
          :version => "v1.2",
          :api_name => "online_tests_zh_submit_result_generate_reports",
          :http_method => "post",
          :params => {
            :test_id => params[:test_id],
            :user_id => current_user.id,
            :result => params[:result],
            :user_model => "WxUser",
            :wx_openid => params[:wx_openid],
            :wx_unionid => params[:wx_unionid]
          }
        })
        tkc_flag, tkc_data = tkc.execute
        if tkc_flag
          status = 200
          result = {
            :message => "success!"
          }
        else
          status = 500
          result = {
            :message => I18n.t("scores.messages.error.upload_failed")
          }
        end
        
      end

    end # resource online test
  end # class
end # module