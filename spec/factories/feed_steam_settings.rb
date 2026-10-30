# frozen_string_literal: true

FactoryBot.define do
  factory :feed_steam_settings, class: "Feeds::Steam::Settings" do
    association :subscription, factory: :feed_subscription
  end
end
