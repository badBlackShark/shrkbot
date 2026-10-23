# frozen_string_literal: true

FactoryBot.define do
  factory :feed_subscribed_event, class: "Feeds::SubscribedEvent" do
    association :subscription, factory: :feed_subscription
    event_type { "Integrations::Steam::PatchNotesPublished" }
  end
end
