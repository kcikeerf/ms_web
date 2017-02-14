Rails.application.routes.draw do
  devise_for :managers, controllers: {sessions: 'managers/sessions', 
                                      registrations: 'managers/registrations', 
                                      passwords: 'managers/passwords'}, 
                        path_names: { sign_in: 'login', 
                                      sign_out: 'logout' }
  devise_for :users, :skip =>[:sessions,:registrations,:passwords]

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
        # delete '/:uid', action: :destroy, as: 'destroy'
        # get '/:uid/edit',action: :edit, as: 'edit'
        # post '/:id/move_node', action: :move_node, as: 'move_node'
        # post 'import_ckp_file'
        post 'combine_node_catalogs_subject_checkpoints'
        post 'list'
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
      get "catalog_tree", on: :collection
      resources :node_catalogs, concerns: :destroy_all do 
        resources :checkpoints, concerns: :destroy_all do
          collection do
            get "tree"
          end
        end
      end
      resources :checkpoints, concerns: :destroy_all do
        collection do
          get "tree"
        end
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
    resources :area_administrators, concerns: :destroy_all
    resources :node_catalogs, concerns: :destroy_all
  end

  mount RuCaptcha::Engine => "/rucaptcha"

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

  resources :subject_checkpoints do 
    collection do 
      get 'ztree_data_list'
    end
  end 

  resource :monitors do
    member do
      get 'get_task_status'
    end
  end
  
  get '/ckeditors/urlimage'=> "ckeditor#urlimage"

end
