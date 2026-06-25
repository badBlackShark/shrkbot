# frozen_string_literal: true

require "rails_helper"

RSpec.describe "database configuration" do
  it "uses a separate database from development so a live-gate session can't pollute the test suite" do
    test_database = ActiveRecord::Base.connection_db_config.database
    development_database = ActiveRecord::Base.configurations.configs_for(env_name: "development").first.database

    expect(test_database).not_to eq(development_database)
  end
end
