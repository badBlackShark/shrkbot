# frozen_string_literal: true

class AddChannelIdToFeedSubscribedEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :feed_subscribed_events, :channel_id, :bigint
  end
end
