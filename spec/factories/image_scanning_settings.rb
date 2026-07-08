# frozen_string_literal: true

FactoryBot.define do
  factory :image_scanning_settings, class: "Moderation::ImageScanning::Settings" do
    association :server_configuration
  end
end
