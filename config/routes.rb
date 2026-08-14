# frozen_string_literal: true

Rails.application.routes.draw do
  draw :twilight_struggle

  get "up" => "rails/health#show", :as => :rails_health_check

  root "pages#home"

  match "/auth/discord/callback", to: "sessions#create", via: [:get, :post]
  get "/auth/failure", to: "sessions#failure"
  delete "/logout", to: "sessions#destroy", as: :logout
  resource :account, only: [:show, :destroy]

  resource :privacy_policy, only: :show, path: "privacy"
  resource :terms_of_service, only: :show, path: "terms"
  resource :imprint, only: :show

  resource :bespoke_plugins, only: :show, path: "bespoke-plugins"

  resources :notifications, only: [:index, :show, :update]
  namespace :notifications do
    resource :read, only: :create
  end

  namespace :admin do
    resource :settings, only: [:show, :update]
    resources :bespoke_plugin_grants, only: [:index, :create, :destroy]
  end

  resources :servers, only: [:index, :show], param: :id do
    resources :plugins, only: :update, param: :key, module: :servers
    scope module: :servers do
      resource :welcomes, only: [:show, :update]
      resource :logging, only: [:show, :update], controller: "logging"
      resource :roles, only: [:show, :update]
      resource :reminders, only: [:show, :update]
      resource :moderation, only: [:show, :update], controller: "moderation"
      resource :lfg, only: [:show, :update], controller: "lfg"
      resource :twilight_struggle, only: [:show, :update], controller: "twilight_struggle" do
        scope module: :twilight_struggle do
          resources :destinations, only: [:edit, :update], param: :tournament_id
          resources :subscriptions, only: [:create, :destroy], param: :tournament_id
        end
      end
      resource :spam_protection, only: [:show, :update], controller: "spam_protection"
      resource :image_scanning, only: [:show, :update], controller: "image_scanning"
      resources :role_sets, only: [] do
        resource :repost, only: :create, module: :role_sets
      end
    end
  end

  get "/preview", to: "previews#show", as: :preview, defaults: {preview: true}
  delete "/preview", to: "previews#destroy"

  scope "/preview", as: :preview, module: :servers, defaults: {preview: true} do
    resource :welcomes, only: [:show, :update]
    resource :logging, only: [:show, :update], controller: "logging"
    resource :roles, only: [:show, :update]
    resource :reminders, only: [:show, :update]
    resource :moderation, only: [:show, :update], controller: "moderation"
    resource :lfg, only: [:show, :update], controller: "lfg"
    resource :spam_protection, only: [:show, :update], controller: "spam_protection"
    resource :image_scanning, only: [:show, :update], controller: "image_scanning"
  end
end
