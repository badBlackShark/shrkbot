FactoryBot.define do
  factory :role_setting do
    association :server_configuration
    sequence(:channel_id) { |n| 300_000 + n }
  end
end
