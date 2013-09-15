JoruriGw::Application.routes.draw do
  scp = "admin"
  mod = "sys"

  scope "_#{scp}" do
    resources "users",
      :controller => "users",
      :path => "" do
        collection do
          get :csvput, :csvup
          post :csvup
      end
    end
  end

  scope "_#{scp}" do
    namespace mod do
      scope :module => scp do
        ## admin
        resources "ldap_groups",
          :controller => "ldap_groups",
          :path => ":parent/ldap_groups"
        resources "ldap_temporaries",
          :controller => "ldap_temporaries",
          :path => "ldap_temporaries" do
            member do
              get :synchronize
              post :synchronize
              put :synchronize
              delete :synchronize
            end
          end
        resources "users",
          :controller => "users",
          :path => "users" do
            collection do
              get :csvput, :csvup
              post :csvup
          end
        end
        resources "groups",
          :controller => "groups",
          :path => ":parent/groups" do
            collection do
              get :csvput, :csvup
              post :csvup
          end
        end
        resources "users_groups",
          :controller => "users_groups",
          :path => ":parent/users_groups" do
            collection do
              get :csvput, :csvup
              post :csvup
          end
        end
      end
    end
  end
  match ':controller(/:action(/:id))(.:format)'
end