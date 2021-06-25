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

    resource :user, only: [:show] do
      collection do
        get :emails
        patch :update_email
        patch :update_password
        post :request_password_reset
        post :reset_password

        get :server_providers
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
      resources :branches, only: [:index, :show]

      member do
        get :refs
      end
    end
  end
end
