# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    kind { "channel_deleted" }
    data { {} }
    association :server_configuration
  end
end
