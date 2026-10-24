# frozen_string_literal: true

class AddImageUrlToIntegrationWatches < ActiveRecord::Migration[8.1]
  def change
    add_column :integration_watches, :image_url, :string
  end
end
