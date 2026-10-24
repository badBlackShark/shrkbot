# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds do
  it "maps every source to a sub-plugin of the feeds plugin" do
    parents = described_class::SOURCE_PLUGINS.values.map { |key| PluginCatalog.find(key)&.parent }

    expect(parents).to all(eq(described_class::PLUGIN_KEY))
  end
end
