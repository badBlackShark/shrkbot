# frozen_string_literal: true

FactoryBot.define do
  factory :moderation_settings, class: "Moderation::Settings" do
    association :server_configuration
  end
end
