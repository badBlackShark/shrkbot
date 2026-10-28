# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds do
  subject(:sources) { described_class::SOURCE_PLUGINS.values.map { |key| PluginCatalog.find(key) } }

  it "is a plugin in the catalog" do
    expect(PluginCatalog.find(:integrations)).to be_present
  end

  it "maps every source to a sub-plugin of the integrations plugin" do
    expect(sources).to be_present.and all(have_attributes(parent: :integrations))
  end

  it "keys every followable event type to a source plugin" do
    expect(described_class::EVENT_TYPES_BY_SOURCE.keys).to match_array(described_class::SOURCE_PLUGINS.values)
  end

  it "defaults each source to a subset of its own event types" do
    by_source = described_class::DEFAULT_EVENT_TYPES_BY_SOURCE

    expect(by_source.keys).to match_array(described_class::EVENT_TYPES_BY_SOURCE.keys)
    expect(by_source).to all(satisfy { |key, defaults| (defaults - described_class::EVENT_TYPES_BY_SOURCE.fetch(key)).empty? })
  end
end
