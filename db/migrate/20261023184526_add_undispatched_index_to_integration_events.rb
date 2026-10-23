# frozen_string_literal: true

class AddUndispatchedIndexToIntegrationEvents < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :integration_events, :created_at, where: "dispatched_at IS NULL", name: "index_integration_events_undispatched", algorithm: :concurrently
  end
end
