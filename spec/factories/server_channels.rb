FactoryBot.define do
  factory :server_channel do
    association :server_configuration
    sequence(:discord_id) { |n| 500_000 + n }
    sequence(:name) { |n| "channel-#{n}" }
    channel_type { 0 }
  end
end
