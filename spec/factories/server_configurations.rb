FactoryBot.define do
  factory :server_configuration do
    sequence(:discord_id) { |n| 100_000 + n }
  end
end
