# frozen_string_literal: true

FactoryBot.define do
  factory :integration_watch, class: "Integrations::Watch" do
    watcher { "Integrations::Steam::NewsWatcher" }
    sequence(:external_id) { |n| (440 + n).to_s }
    name { "Team Fortress 2" }

    trait :twitch do
      watcher { "Integrations::Twitch::ChannelWatcher" }
      sequence(:external_id) { |n| (1000 + n).to_s }
      name { "Some Streamer" }
    end
  end
end
