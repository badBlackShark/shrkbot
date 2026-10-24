# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds do
  subject(:sources) { described_class::SOURCE_PLUGINS.values.map { |key| PluginCatalog.find(key) } }

  it "is a plugin in the catalog" do
    expect(PluginCatalog.find(described_class::PLUGIN_KEY)).to be_present
  end

  it "maps every source to a sub-plugin of the feeds plugin" do
    expect(sources).to be_present.and all(have_attributes(parent: described_class::PLUGIN_KEY))
  end

  it "keys every followable event type to a source plugin" do
    expect(described_class::EVENT_TYPES_BY_SOURCE.keys).to match_array(described_class::SOURCE_PLUGINS.values)
  end

  it "leaves articles off by default" do
    expect(described_class::DEFAULT_EVENT_TYPES).to eq(described_class::EVENT_TYPES - ["Integrations::Steam::ArticlePublished"])
  end
end
