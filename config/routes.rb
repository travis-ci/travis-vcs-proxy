Rails.application.routes.draw do
  root to: 'home#index'

  post :listener, to: 'v1/webhooks#receive'

  scope :v1 do
    use_doorkeeper do
      skip_controllers :applications, :token_info
    end
  end

  scope :v1, module: :v1 do
    devise_for :users,
      controllers: {
        sessions: 'v1/users/sessions',
        registrations: 'v1/users/registrations',
        confirmations: 'v1/users/confirmations'
      },
      path_names: {
        sign_in: 'login',
        sign_out: 'logout',
        register: 'sign_up'
      }

    scope 'users/confirmation' do
      devise_scope :user do
        post :resend, to: 'users/confirmations#resend', as: :resend_confirmation
      end
    end

    resource :user, only: [:show] do
      collection do
        get :emails
        patch :update_email
        patch :update_password
        post :request_password_reset
        post :reset_password
        post :sync

        get :organizations
        get :organizations_for_choice
        get :repositories
      end

      resource :two_factor_auth, controller: 'users/two_factor_auth', only: [] do
        collection do
          get :url
          get :codes
          post :enable
        end
      end
    end

    resources :organizations, only: [:create, :show, :update, :destroy] do
      post :invite

      collection do
        get :by_name
        post :add_by_name
        post :confirm_invitation
      end

      member do
        post :authenticate
        post :forget
        post :sync

        get :users
        get :repositories
      end

      resources :user, controller: 'organizations/organization_users', only: [] do
        post :add
        post :update
        post :remove
        get :show
      end
    end

    resources :repositories, only: [:create, :show, :update, :destroy, :by_name, :add] do
      resources :branches, controller: 'repositories/branches', only: [:index, :show]
      resources :commits, controller: 'repositories/commits', only: [:index, :show]
      resources :webhooks, controller: 'repositories/webhooks', only: [:index, :show, :create, :update]
      resources :token, controller: 'repositories/token', only: [] do
        collection do
          get :get
          patch :update
          delete :destroy
        end
      end

      member do
        get :refs
        get 'content/:ref/(*path)', action: :content, format: false
        post :sync
      end
      get :by_name
    end
  end
end
