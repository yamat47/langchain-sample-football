Rails.application.routes.draw do
  resources :book_assistant, only: [:index] do
    collection do
      post :query
      post :new_chat
    end
  end

  namespace :admin do
    root "dashboard#index"
    get "dashboard", to: "dashboard#index"
    resources :books, only: [:index, :show] do
      resources :reviews, only: [:index]
      member do
        get :similar
      end
    end
    resources :book_queries, only: [:index, :show]
  end

  root "book_assistant#index"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
