FactoryBot.define do
  factory :server_role do
    association :server_configuration
    sequence(:discord_id) { |n| 600_000 + n }
    sequence(:name) { |n| "role-#{n}" }
  end
end
