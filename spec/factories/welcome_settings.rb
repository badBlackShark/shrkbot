FactoryBot.define do
  factory :welcome_settings, class: "Welcomes::Settings" do
    association :server_configuration
    sequence(:channel_id) { |n| 500_000 + n }
  end
end
