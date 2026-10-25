# frozen_string_literal: true

class RenameFeedsPluginsToIntegrations < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      execute "UPDATE plugins SET key = 'integrations', name = 'Integrations' WHERE key = 'feeds'"
      execute "UPDATE plugins SET key = 'steam', name = 'Steam' WHERE key = 'steam_news'"
    end
  end

  def down
    safety_assured do
      execute "UPDATE plugins SET key = 'feeds', name = 'Feeds' WHERE key = 'integrations'"
      execute "UPDATE plugins SET key = 'steam_news', name = 'Steam News' WHERE key = 'steam'"
    end
  end
end
