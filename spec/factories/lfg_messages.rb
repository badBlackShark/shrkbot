# frozen_string_literal: true

FactoryBot.define do
  factory :lfg_message, class: "Lfg::Message" do
    association :server_configuration
    sequence(:channel_id) { |n| 2_000 + n }
    sequence(:message_id) { |n| 5_000 + n }
  end
end
