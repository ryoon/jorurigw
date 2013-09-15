JoruriGw::Application.routes.draw do
  mod = "system"
  scp = "admin"
  
  namespace mod do
    scope :module => scp do
      ## admin
      resources :users do
        collection do
          get :csv, :csvget, :csvup, :csvset, :list
          post :csvup, :csvset
        end
        member do
          get :csvshow
        end
      end
      resources :groups,
        :path => ":parent/groups" do
          collection do
            get :list
          end
        end
      resources :users_groups,
        :path => ":parent/users_groups" do
          collection do
            get :list
          end
        end
      resources "roles" do
        collection do
          get :user_fields
        end
      end
      resources "role_developers"
      resources "priv_names"
      resources "role_names"
      resources "role_name_privs" do
        collection do
          get :getajax
        end
      end
      resources :custom_groups do
        collection do
          get :create_all_group, :synchro_all_group, :user_add_sort_no
          put :sort_update
          post :get_users
        end
      end
    end
  end
  
  ##API
  match 'api/checker'         => 'system/admin/api#checker'
  match 'api/checker_login'   => 'system/admin/api#checker_login'
  match 'api/air_sso'         => 'system/admin/api#sso_login'
  
  match ':controller(/:action(/:id))(.:format)'
end
