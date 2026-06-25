# frozen_string_literal: true

FactoryBot.define do
  factory :plugin_activation do
    association :server_configuration
    association :plugin
    enabled { false }
  end
end
