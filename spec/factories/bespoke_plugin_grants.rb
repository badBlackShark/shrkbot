# frozen_string_literal: true

FactoryBot.define do
  factory :bespoke_plugin_grant do
    server_configuration
    sequence(:plugin_key) { |n| "bespoke_#{n}" }
  end
end
