class Reminder < ApplicationRecord
  # server_id is null for DM reminders. No belongs_to: reminders are keyed by raw
  # Discord snowflakes (server/user/channel), not local FKs.
  validates :user_id, :channel_id, :remind_at, :message, presence: true
end
