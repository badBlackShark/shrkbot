module Reminders
  class Reminder < ApplicationRecord
    # Namespaced model would otherwise derive an ambiguous table name.
    self.table_name = "reminders"

    validates :user_id, :channel_id, :remind_at, :message, presence: true

    scope :for_user, ->(user_id) { where(user_id:).order(:remind_at) }
  end
end
