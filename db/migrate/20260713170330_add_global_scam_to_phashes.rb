# frozen_string_literal: true

class AddGlobalScamToPhashes < ActiveRecord::Migration[8.1]
  def change
    add_column :phashes, :global_scam, :boolean, default: false, null: false
    add_index :phashes, :global_scam, where: "global_scam", name: "index_phashes_on_global_scam"
  end
end
