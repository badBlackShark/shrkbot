# frozen_string_literal: true

FactoryBot.define do
  factory :assignable_role, class: "Roles::AssignableRole" do
    association :role_set
    sequence(:role_id) { |n| 400_000 + n }
  end
end
