# frozen_string_literal: true

FactoryBot.define do
  factory :feed_post, class: "Feeds::Post" do
    association :subscription, factory: :feed_subscription
    sequence(:story_key) { |n| "story-#{n}" }
  end
end
