# frozen_string_literal: true

class AddUrlToIntegrationWatches < ActiveRecord::Migration[8.1]
  def change
    add_column :integration_watches, :url, :string
  end
end
