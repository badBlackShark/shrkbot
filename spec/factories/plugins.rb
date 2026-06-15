FactoryBot.define do
  factory :plugin do
    sequence(:key) { |n| "plugin_#{n}" }
    name { "Plugin" }
  end
end
