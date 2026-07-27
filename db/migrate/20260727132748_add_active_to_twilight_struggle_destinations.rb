# frozen_string_literal: true

class AddActiveToTwilightStruggleDestinations < ActiveRecord::Migration[8.1]
  def change
    add_column :twilight_struggle_destinations, :active, :boolean, null: false, default: true
  end
end
