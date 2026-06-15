FactoryBot.define do
  factory :setting do
    sequence(:key) { |n| "setting_#{n}" }
    value { "v" }
  end
end
