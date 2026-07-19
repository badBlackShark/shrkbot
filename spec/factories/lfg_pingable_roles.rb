# frozen_string_literal: true

FactoryBot.define do
  factory :lfg_pingable_role, class: "Lfg::PingableRole" do
    association :lfg_settings
    sequence(:role_id) { |n| 1_000 + n }
  end
end
