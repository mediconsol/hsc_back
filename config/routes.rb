Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    namespace :v1 do
      resources :employees, except: [:new, :edit]
      resources :documents, except: [:new, :edit] do
        member do
          post :request_approval
        end
      end
      resources :department_posts, except: [:new, :edit]
      resources :announcements, except: [:new, :edit]
      root 'home#index'
      post 'auth/login', to: 'auth#login'
      delete 'auth/logout', to: 'auth#logout'
      get 'auth/me', to: 'auth#me'
    end
  end

  # Root route for API
  root 'api/v1/home#index'
end
