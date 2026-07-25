# frozen_string_literal: true

namespace :twilight_struggle, path: "twilight-struggle" do
  resources :tournaments, only: [:index, :edit, :update] do
    resource :claim, only: [:create, :destroy], module: :tournaments
  end
end

namespace :api do
  namespace :twilight_struggle, path: "twilight-struggle" do
    namespace :v1 do
      resources :tournaments, only: [:update, :destroy], param: :external_id
      resources :games, only: [:update, :destroy], param: :external_id
    end
  end
end
