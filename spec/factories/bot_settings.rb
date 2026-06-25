# frozen_string_literal: true

FactoryBot.define do
  factory :bot_setting do
    sequence(:key) { |n| "bot_setting_#{n}" }
    value { "v" }
  end
end
