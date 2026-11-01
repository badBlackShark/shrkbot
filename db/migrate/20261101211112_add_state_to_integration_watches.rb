# frozen_string_literal: true

class AddStateToIntegrationWatches < ActiveRecord::Migration[8.1]
  def change
    add_column :integration_watches, :state, :jsonb, null: false, default: {}
  end
end
