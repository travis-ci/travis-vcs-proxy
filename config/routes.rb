Rails.application.routes.draw do
  root to: 'home#index'

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

        get :server_providers
      end

      resource :two_factor_auth, controller: 'users/two_factor_auth', only: [] do
        collection do
          get :url
          get :codes
          post :enable
        end
      end
    end

    resources :server_providers, only: [:create, :show, :update] do
      member do
        post :authenticate
        post :forget
        post :sync

        get :repositories
      end
    end

    resources :repositories, only: [:show] do
      resources :branches, controller: 'repositories/branches', only: [:index, :show]
      resources :token, controller: 'repositories/token', only: [] do
        collection do
          patch :update
          delete :destroy
        end
      end

      member do
        get :refs
      end
    end
  end
end
