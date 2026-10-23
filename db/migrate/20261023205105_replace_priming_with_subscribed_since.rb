# frozen_string_literal: true

class ReplacePrimingWithSubscribedSince < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      add_column :feed_subscribed_events, :subscribed_since, :datetime, null: false, default: -> { "CURRENT_TIMESTAMP" }
      remove_column :integration_watches, :primed_at, :datetime
    end
  end
end
