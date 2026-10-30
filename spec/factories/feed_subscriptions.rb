# frozen_string_literal: true

FactoryBot.define do
  factory :feed_subscription, class: "Feeds::Subscription" do
    association :server_configuration
    association :watch, factory: :integration_watch
    channel_id { 555_000 }

    after(:build) do |subscription|
      subscription.build_settings if Feeds::Steam.watchers.include?(subscription.watch.watcher)
    end

    trait :active do
      after(:create) do |subscription|
        Prosopite.pause do
          %w[integrations steam].each do |key|
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

    factory :steam_feed_subscription do
      transient do
        role_id { nil }
        body_length { nil }
        languages { nil }
      end

      after(:build) do |subscription, evaluator|
        given = {role_id: evaluator.role_id, body_length: evaluator.body_length, languages: evaluator.languages}.compact
        subscription.settings.assign_attributes(given)
      end
    end
  end
end
