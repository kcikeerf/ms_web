Rails.application.routes.draw do

  mount RuCaptcha::Engine => "/rucaptcha"
  root 'welcomes#index'
  get '/about_us', to: 'welcomes#about_us'
  get '/contact', to: 'welcomes#contact'

  # routes for quiz_paper controller

  resources :node_structures do
    collection do 
      get 'get_subjects'
      get 'get_grades'
      get 'get_versions'
      get 'get_units'
      get 'list'
      get 'catalog_list'
    end
  end

  resource :quizs do
    member do
      post 'single_quiz_file_upload' 
      post 'quiz_create_type1upload'
      post 'quiz_create_type1save'
      # post 'single_quiz_save'
      get 'quiz_list'
      get 'quiz_get'
      delete 'single_quiz_delete'
      get 'single_quiz_edit'
      patch 'single_quiz_update'
    end
    get 'single_quiz'
    post 'subject_related_data'
    post 'single_quiz_save'
  end

  resources :checkpoints do 
    collection do 
      post 'get_nodes'
      get 'get_node_count'
#      get 'get_child_nodes'
#      get 'get_all_nodes'
#      post 'save_node'
#      post 'update_node'
#      post 'delete_node'
      get 'dimesion_tree'
      get 'get_ckp_data'
      get 'get_tree_data_by_subject'
      get 'get_ckp_type_system'
    end
  end

  resources :subject_checkpoints do 
    collection do 
      get 'ztree_data_list'
    end
  end 

  resources :score_reports do 
    collection do 
      get 'simple'
      get 'profession'
    end
  end


  resource :pupils do
    member do
      get 'my_home'
      get 'my_report'
    end
  end

  resource :teachers do
    member do
      get 'my_home'
      get 'my_pupil'
      get 'test_report'
    end
  end

  resource :analyzers do
    get 'my_home'
    get 'my_paper(/:page)', action: 'my_paper', as: 'my_paper'
    get 'my_log'
    get 'region'
  end

  resource :tenant_administrators do
    member do
      get 'my_home'
      get 'my_analyzer'
      get 'my_teacher'
      get 'my_paper'
    end
  end

  resource :project_administrators do
    member do
      get 'my_home'
      get 'my_paper'
    end
  end

  resource :papers do
    member do
      post 'paper_answer_upload'
      post 'save_paper'
      get 'get_paper'
      get 'get_saved_paper'
      post 'submit_paper'
      post 'save_analyze'
      # get 'get_saved_analyze'
      post 'submit_analyze'
      post 'generate_all_reports'
      get 'get_empty_score_file'
      # post 'upload_filled_score_file'
      get 'download_original_paper_answer'
      get 'download_modified_paper_answer_emptyscore'
      get 'download_imported_score'
      get 'download_user_password_reporturl'
      match 'import_filled_score', via: [:get, :post, :patch]
      match 'import_filled_result', via: [:get, :post, :patch]
      get 'download'
      get 'download_page'
      post 'outline_list'
    end 
  end

  resource :reports do
    member do
      post 'generate_all_reports'
      post 'generate_reports'
      get 'class_report'
      get 'pupil_report'
      get 'get_grade_report'
      get 'get_class_report'
      get 'get_pupil_report'
      # get 'square'
      get 'check/:codes', to: "reports#first_login_check_report"
      get 'new_square'
      get 'square_v1_1'
      get 'project'
      get 'grade'
      get 'klass'
      get 'pupil'
    end
  end

  match "/reports_warehouse/tests/*any_path", to: "reports_warehouse#get_report_file", via: [:get]

  resource :monitors do
    member do
      get 'get_task_status'
    end
  end

  resource :profile, only: [] do 
    get 'message'
    get 'account_binding'
    get 'binding_or_unbinding_mobile_succeed'
    get 'binding_or_unbinding_email_succeed'
    get 'modify_mobile_succeed'
    get 'modify_email_succeed'
    match 'init', via: [:get, :post]
    match 'binding_or_unbinding_mobile', via: [:get]#[:get, :post]
    match 'binding_or_unbinding_email', via: [:get]#[:get, :post]
    match 'verified_email', via: [:get]#[:get, :post]
    match 'modify_email', via: [:get]#[:get, :post]
    match 'verified_mobile', via: [:get]#[:get, :post]
    match 'modify_mobile', via: [:get]#[:get, :post]
    post 'head_image_upload'
    post 'save_info'
  end

  resources :messages, only: [] do 
    collection do 
      # post 'send_sms_auth_number'
      # post 'send_email_auth_number'
      # post 'send_sms_forgot_password'
      # post 'send_email_forgot_password'
    end
  end
  
  get '/ckeditors/urlimage'=> "ckeditor#urlimage"

  # resources :librarys, :online_tests
  # defined routes for user authentication
  devise_for :users,
    controllers: { sessions: 'users/sessions',
                   registrations: 'users/registrations',
                   passwords: 'users/passwords'},
    path_names: { sign_in: 'login', 
                  sign_out: 'logout' }

  devise_scope :user do
    get 'users/get_user_password_file', :to => 'users/registrations#get_user_password_file'
    post 'users/passwords/user_captcha_validate'
  end

  use_doorkeeper do
    skip_controllers :authorizations, :applications,
      :authorized_applications
  end

  #######################################
  ### errors
  
  get "/403", :to => "errors#error_403"
  get "/404", :to => "errors#error_404"
  get "/422", :to => "errors#error_404"
  get "/500", :to => "errors#error_500"
  get "/505", :to => "errors#error_505"

  #######################################
  ### Wechat API

  #constraints(:host => 'wx.k12ke.com') do
    namespace :wx do
      resource :auths do
        post 'unbind'
        post 'check_bind'
        post 'get_binded_users'
        # post 'bind'
      end

      resource :reports do
        post 'get_list'
        post 'get_pupil_report'
        # post 'get_indivisual_report_part'
        # post 'get_indivisual_report_1'
      end

      # resource :papers do
      #   post "get_quizs"
      #   post "submit_quiz_score"
      # end

      post 'bind', to: "auths#wx_bind"
      match 'get_indivisual_report_part', to: "reports#get_indivisual_report_part",via: [:post, :options]
      match 'get_indivisual_report_1', to: "reports#get_indivisual_report_1", via:[:post, :options]
      match 'get_quizs', to: "papers#get_quizs",via: [:post, :options]
      match 'submit_quiz_score', to: "papers#submit_quiz_score",via: [:post, :options]
    end
  #end
  #######################################

  #######################################
  ### API V1.1
  constraints do
    mount Auths::API => "/"
    mount PaperOnlineTest::API => "/"
    mount Reports::API => "/"
    mount ReportsWarehouse::API => "/"
    mount Monitoring::API => "/"
    mount Tenants::API => "/"
    mount Quizs::API => "/"
  end

  ### API V1.2
  mount ApiV12Auths::API => "/api/v1.2/"
  mount ApiV12OnlineTests::API => "/api/v1.2/"
  mount ApiV12Reports::API => "/api/v1.2/"
  mount ApiV12ReportsWarehouse::API => "/api/v1.2/"
  mount ApiV12Monitoring::API => "/api/v1.2/"
  mount ApiV12Tenants::API => "/api/v1.2/"
  mount ApiV12Quizs::API => "/api/v1.2/"
  #######################################

  # match '*path', to: 'welcomes#error_404', via: :all
  #require 'sidekiq/web'
  #mount Sidekiq::Web => '/sidekiq'
  get '*path', to: 'welcomes#index'
end
