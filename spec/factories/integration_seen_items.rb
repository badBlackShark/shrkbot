# frozen_string_literal: true

FactoryBot.define do
  factory :integration_seen_item, class: "Integrations::SeenItem" do
    association :watch, factory: :integration_watch
    sequence(:external_id) { |n| (1000 + n).to_s }
  end
end
