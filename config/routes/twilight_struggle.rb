# frozen_string_literal: true

namespace :api do
  namespace :twilight_struggle, path: "twilight-struggle" do
    namespace :v1 do
      resources :tournaments, only: [:update, :destroy], param: :external_id
      resources :games, only: [:update, :destroy], param: :external_id
    end
  end
end
