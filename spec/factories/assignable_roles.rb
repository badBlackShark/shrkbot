FactoryBot.define do
  factory :assignable_role do
    association :role_setting
    sequence(:role_id) { |n| 400_000 + n }
    label { "Role" }
  end
end
