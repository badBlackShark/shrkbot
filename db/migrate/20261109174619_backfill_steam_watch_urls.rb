# frozen_string_literal: true

class BackfillSteamWatchUrls < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      execute "UPDATE integration_watches SET url = 'https://store.steampowered.com/app/' || external_id || '/' " \
        "WHERE watcher = 'Integrations::Steam::NewsWatcher' AND url IS NULL"
    end
  end

  def down
  end
end
