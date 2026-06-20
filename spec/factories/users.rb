FactoryBot.define do
  factory :user do
    sequence(:discord_id) { |n| 700_000 + n }
    sequence(:username) { |n| "user-#{n}" }
  end
end
