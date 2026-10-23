# frozen_string_literal: true

FactoryBot.define do
  factory :feed_subscription, class: "Feeds::Subscription" do
    association :server_configuration
    association :watch, factory: :integration_watch
    channel_id { 555_000 }

    trait :active do
      after(:create) do |subscription|
        Prosopite.pause do
          %w[feeds steam_news].each do |key|
            create(
              :plugin_activation,
              server_configuration: subscription.server_configuration,
              plugin: create(:plugin, key:),
              enabled: true
            )
          end
        end
      end
    end
  end
end
