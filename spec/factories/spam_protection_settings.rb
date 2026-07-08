# frozen_string_literal: true

FactoryBot.define do
  factory :spam_protection_settings, class: "Moderation::SpamProtection::Settings" do
    association :server_configuration
  end
end
