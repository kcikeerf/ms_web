Rails.application.routes.draw do
  devise_for :managers, controllers: {sessions: 'managers/sessions', 
                                      registrations: 'managers/registrations', 
                                      passwords: 'managers/passwords'}, 
                        path_names: { sign_in: 'login', 
                                      sign_out: 'logout' }

  namespace :managers do
    root 'mains#index'


    concern :destroy_all do
      delete 'destroy_all', on: :collection
    end  

    resources :mains do    
      get 'navigation'
    end
    
    resources :checkpoints, :except => [:edit, :destroy] do      
      collection do
        delete '/:uid', action: :destroy, as: 'destroy'
        get '/:uid/edit',action: :edit, as: 'edit'
        post '/:id/move_node', action: :move_node, as: 'move_node'
        post 'import_ckp_file'
      end
    end

    resources :subject_checkpoints, concerns: :destroy_all do    
      collection do   
        post '/:id/move_node', action: :move_node, as: 'move_node'
        get 'list'
        get 'get_subject_volume_ckps'
        get 'get_volume_catalog_ckps'
        post 'import_ckp_file'
      end
    end

    resources :roles, concerns: :destroy_all do
      resources :role_permissions, concerns: :destroy_all 
    end

    resources :node_structures, concerns: :destroy_all do 
      post 'add_ckps', on: :collection
      resources :node_catalogs, concerns: :destroy_all do 
        post 'add_ckps', on: :collection
      end
    end
    
    resources :permissions, concerns: :destroy_all
 
    resources :tenants, concerns: :destroy_all do
      collection do
        #delete 'destroy_all', :to => "tenants#destroy_all"
      end
    end

    resources :areas do
      collection do
        get 'get_province'
        get 'get_city'
        get 'get_district'
        get 'get_tenants'
      end
    end

    resources :analyzers, concerns: :destroy_all
    resources :teachers, concerns: :destroy_all
    resources :pupils, concerns: :destroy_all
    resources :tenant_administrators, concerns: :destroy_all
    resources :project_administrators, concerns: :destroy_all
  end

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
      get 'get_catalogs_and_tree_data'
      get 'get_ckp_data' 
      # get 'get_tree_data_by_subject' 
      get 'get_ckp_data_by_volume_catalog'
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
      get 'get_saved_analyze'
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
    end 
  end

  resource :reports do
    member do
      post 'generate_all_reports'
      get 'class_report'
      get 'pupil_report'
      get 'get_grade_report'
      get 'get_class_report'
      get 'get_pupil_report'
      # get 'square'
      get 'check/:codes', to: "reports#first_login_check_report"
      get 'new_square'
      get 'grade'
      get 'klass'
      get 'pupil'
    end
  end

  resource :monitors do
    member do
      get 'get_task_status'
    end
  end

  # resource :grade_reports do
  #   member do
  #     get 'index'
  #   end
  # end

  # resource :class_reports do
  #   member do
  #     get 'index'
  #   end
  # end

  # resource :pupil_reports do
  #   member do
  #     get 'index'
  #   end
  # end

  # resource :gradereport do
  #   member do
  #     get 'index', to: "gradereport#index"
  #     get 'demo',to: "gradereport#demo"
  #   end
  # end

  # resource :classreport do
  #   member do
  #     get 'index', to: "classreport#index"
  #     get 'demo',to: "classreport#demo"
  #   end
  # end

  # resource :pupilreport do
  #   member do
  #     get 'index', to: "pupilreport#index"
  #     get 'demo', to: "pupilreport#demo"
  #   end
  # end

  resource :profile, only: [] do 
    get 'message'
    get 'account_binding'
    get 'binding_or_unbinding_mobile_succeed'
    get 'binding_or_unbinding_email_succeed'
    get 'modify_mobile_succeed'
    get 'modify_email_succeed'
    match 'init', via: [:get, :post]
    match 'binding_or_unbinding_mobile', via: [:get, :post]
    match 'binding_or_unbinding_email', via: [:get, :post]
    match 'verified_email', via: [:get, :post]
    match 'modify_email', via: [:get, :post]
    match 'verified_mobile', via: [:get, :post]
    match 'modify_mobile', via: [:get, :post]
    post 'head_image_upload'
    post 'save_info'
  end

  resources :messages, only: [] do 
    collection do 
      post 'send_sms_auth_number'
      post 'send_email_auth_number'
      post 'send_sms_forgot_password'
      post 'send_email_forgot_password'
    end
  end
  
  get '/ckeditors/urlimage'=> "ckeditor#urlimage"

  resources :librarys, :online_tests
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

  ActiveAdmin.routes(self)
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

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

  # match '*path', to: 'welcomes#error_404', via: :all
end
