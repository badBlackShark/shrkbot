# frozen_string_literal: true

FactoryBot.define do
  factory :feed_post, class: "Feeds::Post" do
    association :subscription, factory: :feed_subscription
    sequence(:story_key) { |n| "story-#{n}" }

    trait :sent do
      channel_id { 555_000 }
      sequence(:message_id) { |n| 900_000 + n }
    end
  end
end
