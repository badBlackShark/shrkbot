# frozen_string_literal: true

class MoveFeedRoleToSubscribedEvents < ActiveRecord::Migration[8.1]
  def up
    add_column :feed_subscribed_events, :role_id, :bigint
    safety_assured do
      execute <<~SQL.squish
        UPDATE feed_subscribed_events
        SET role_id = feed_subscriptions.role_id
        FROM feed_subscriptions
        WHERE feed_subscribed_events.subscription_id = feed_subscriptions.id
          AND feed_subscriptions.role_id IS NOT NULL
      SQL
      remove_column :feed_subscriptions, :role_id
    end
  end

  def down
    add_column :feed_subscriptions, :role_id, :bigint
    safety_assured do
      execute <<~SQL.squish
        UPDATE feed_subscriptions
        SET role_id = (
          SELECT e.role_id FROM feed_subscribed_events e
          WHERE e.subscription_id = feed_subscriptions.id AND e.role_id IS NOT NULL
          ORDER BY e.created_at, e.id LIMIT 1
        )
      SQL
      remove_column :feed_subscribed_events, :role_id
    end
  end
end
