# frozen_string_literal: true

class AddNotificationTemplateToFeedSubscribedEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :feed_subscribed_events, :notification_template, :text
  end
end
