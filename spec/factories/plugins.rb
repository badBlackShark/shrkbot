# frozen_string_literal: true

FactoryBot.define do
  factory :plugin do
    sequence(:key) { |n| "plugin_#{n}" }
    name { "Plugin" }

    initialize_with { Plugin.find_or_initialize_by(key:) }
  end
end
