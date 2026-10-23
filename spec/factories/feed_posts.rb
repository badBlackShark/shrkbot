# frozen_string_literal: true

FactoryBot.define do
  factory :feed_post, class: "Feeds::Post" do
    association :subscription, factory: :feed_subscription
    sequence(:story_key) { |n| "story-#{n}" }
    discord_channel_id { 555_000 }
    discord_message_id { 777_000 }
  end
end
