# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::Settings do
  subject(:settings) { build(:moderation_settings) }

  it "belongs to a server configuration" do
    expect(settings.server_configuration).to be_present
  end

  it "uses the correct table name" do
    expect(described_class.table_name).to eq("moderation_settings")
  end

  it "persists via the factory" do
    expect { create(:moderation_settings) }.to change(described_class, :count).by(1)
  end
end
