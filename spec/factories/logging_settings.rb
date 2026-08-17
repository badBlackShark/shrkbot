# frozen_string_literal: true

FactoryBot.define do
  factory :logging_settings, class: "Logging::Settings" do
    association :server_configuration
    sequence(:channel_id) { |n| 200_000 + n }
  end
end
