FactoryBot.define do
  factory :channel_overwrite do
    association :server_channel
    sequence(:target_id) { |n| 700_000 + n }
    target_type { "role" }
    allow { 0 }
    deny { 0 }
  end
end
