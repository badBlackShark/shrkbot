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
end
