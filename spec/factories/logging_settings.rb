FactoryBot.define do
  factory :logging_setting do
    association :server_configuration
    sequence(:channel_id) { |n| 200_000 + n }
  end
end
