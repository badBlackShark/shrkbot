# frozen_string_literal: true

class CopyCustomMessagesToNotificationTemplates < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      execute "UPDATE feed_subscribed_events SET notification_template = template WHERE template IS NOT NULL AND notification_template IS NULL"
    end
  end

  def down
    safety_assured do
      execute "UPDATE feed_subscribed_events SET notification_template = NULL WHERE notification_template = template"
    end
  end
end
