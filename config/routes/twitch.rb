# frozen_string_literal: true

namespace :api do
  namespace :twitch do
    resource :event_sub, only: :create, path: "eventsub"
  end
end
