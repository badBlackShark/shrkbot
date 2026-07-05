# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  root "pages#home"

  match "/auth/discord/callback", to: "sessions#create", via: [:get, :post]
  get "/auth/failure", to: "sessions#failure"
  delete "/logout", to: "sessions#destroy", as: :logout

  resources :notifications, only: [:index, :show, :update]
  namespace :notifications do
    resource :read, only: :create
  end

  namespace :admin do
    resource :settings, only: [:show, :update]
  end

  resources :servers, only: [:index, :show], param: :id do
    resources :plugins, only: :update, param: :key, module: :servers
    scope module: :servers do
      resource :welcomes, only: [:show, :update]
      resource :logging, only: [:show, :update], controller: "logging"
      resource :roles, only: [:show, :update]
      resource :reminders, only: [:show, :update]
      resources :role_sets, only: [] do
        resource :repost, only: :create, module: :role_sets
      end
    end
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
