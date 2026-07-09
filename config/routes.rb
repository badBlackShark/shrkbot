# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", :as => :rails_health_check

  root "pages#home"

  match "/auth/discord/callback", to: "sessions#create", via: [:get, :post]
  get "/auth/failure", to: "sessions#failure"
  delete "/logout", to: "sessions#destroy", as: :logout
  resource :account, only: [:show, :destroy]

  resource :privacy_policy, only: :show, path: "privacy"
  resource :terms_of_service, only: :show, path: "terms"
  resource :imprint, only: :show

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
      resource :moderation, only: [:show, :update], controller: "moderation"
      resource :spam_protection, only: [:show, :update], controller: "spam_protection"
      resource :image_scanning, only: [:show, :update], controller: "image_scanning"
      resources :role_sets, only: [] do
        resource :repost, only: :create, module: :role_sets
      end
    end
  end
end
