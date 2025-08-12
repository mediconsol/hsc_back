Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  
  # Enhanced health check endpoints for monitoring
  get "health" => "health#show"
  get "health/detailed" => "health#detailed"
  get "health/version" => "health#version"

  # API Documentation (only in dev/test to avoid missing constant errors in production)
  if Rails.env.development? || Rails.env.test?
    mount Rswag::Ui::Engine => '/api-docs'
    mount Rswag::Api::Engine => '/api-docs'
  end

  # API routes
  namespace :api do
    namespace :v1 do
      resources :facilities, except: [:new, :edit] do
        collection do
          get :statistics
        end
      end
      resources :assets, except: [:new, :edit] do
        collection do
          get :statistics
          get :warranty_expiring
        end
        member do
          patch :change_status
          patch :change_location
        end
      end
      resources :maintenances, except: [:new, :edit] do
        collection do
          get :overdue
          get :upcoming
          get :statistics
        end
        member do
          patch :start
          patch :complete
          patch :cancel
        end
      end
      
      # 예산/재무 관리 라우트
      resources :budgets, except: [:new, :edit] do
        collection do
          get :statistics
          get :departments
          get :categories
        end
      end
      
      resources :expenses, except: [:new, :edit] do
        collection do
          get :statistics
        end
        member do
          patch :approve
          patch :reject
          patch :mark_as_paid
        end
      end
      
      resources :invoices, except: [:new, :edit] do
        collection do
          get :statistics
          get :vendors
        end
        member do
          patch :start_review
          patch :approve
          patch :reject
          patch :mark_as_paid
        end
      end
      resources :conversation_histories, only: [:index, :show, :create, :destroy] do
        collection do
          get :recent_context
          get :session_messages
          get :stats
        end
      end
      resources :employees, except: [:new, :edit]
      resources :attendances, except: [:new, :edit] do
        collection do
          post :check_in
          post :check_out
          get :statistics
          get :today_status
        end
      end
      resources :leave_requests, except: [:new, :edit] do
        collection do
          get :pending_approvals
          get :statistics
          get :annual_leave_status
        end
        member do
          patch :approve
          patch :reject
          patch :cancel
        end
      end
      resources :payrolls, except: [:new, :edit] do
        collection do
          get :monthly_summary
        end
      end
      resources :documents, except: [:new, :edit] do
        resources :approvals, only: [] do
          member do
            patch :approve
            patch :reject
            patch :delegate
          end
        end
        member do
          post :request_approval
          patch :cancel_approval
          patch :recall_approval
        end
      end
      
      # 예약/접수 관련 라우트
      resources :patients, except: [:new, :edit] do
        collection do
          get :search
          get :statistics
        end
        member do
          get :full_info
          get :checkup_history
          get :medical_summary
        end
      end
      
      # 건강검진 관리 라우트
      resources :health_checkups, except: [:new, :edit] do
        resources :checkup_results, except: [:new, :edit]
        member do
          patch :start_checkup, :complete_checkup
        end
      end
      
      resources :medical_histories, except: [:new, :edit]
      resources :family_histories, except: [:new, :edit]
      
      resources :appointments, except: [:new, :edit] do
        collection do
          get :dashboard
          post :create_online
        end
        member do
          patch :confirm
          patch :cancel  
          patch :arrive
          patch :complete
        end
      end
      
      resources :department_posts, except: [:new, :edit] do
        resources :comments, except: [:new, :edit, :show, :update] do
          member do
            post :create_reply
          end
        end
      end
      resources :announcements, except: [:new, :edit] do
        member do
          patch :toggle_pin
          get :read_status
        end
      end
      # AI 어시스턴트 라우트
      namespace :ai do
        post :chat
      end
      
      root 'home#index'
      post 'auth/login', to: 'auth#login'
      post 'auth/refresh', to: 'auth#refresh'
      delete 'auth/logout', to: 'auth#logout'
      get 'auth/me', to: 'auth#me'
    end
  end

  # Root route for API
  root 'api/v1/home#index'
end
