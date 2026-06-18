FactoryBot.define do
  factory :role_set, class: "Roles::Set" do
    association :role_setting
    sequence(:name) { |n| "Set #{n}" }
    selection_mode { "multi" }
  end
end
