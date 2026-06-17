FactoryBot.define do
  factory :assignable_role, class: "Roles::AssignableRole" do
    association :role_set
    sequence(:role_id) { |n| 400_000 + n }
    label { "Role" }
  end
end
