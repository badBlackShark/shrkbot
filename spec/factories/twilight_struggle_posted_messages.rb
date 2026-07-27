# frozen_string_literal: true

FactoryBot.define do
  factory :twilight_struggle_posted_message, class: "TwilightStruggle::PostedMessage" do
    association :game, factory: :twilight_struggle_game
    association :server_configuration
    discord_channel_id { 4242 }
    sequence(:discord_message_id) { |n| 5000 + n }
  end
end
