# frozen_string_literal: true

FactoryBot.define do
  # server_id stays nil by default (DM-style); set it explicitly for server reminders.
  factory :reminder, class: "Reminders::Reminder" do
    sequence(:user_id) { |n| 600_000 + n }
    sequence(:channel_id) { |n| 700_000 + n }
    remind_at { 1.hour.from_now }
    message { "do the thing" }
    deliver_via_dm { false }
  end
end
