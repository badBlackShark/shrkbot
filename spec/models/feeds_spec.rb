# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds do
  it "is a plugin in the catalog" do
    expect(PluginCatalog.find(:integrations)).to be_present
  end

  describe ".sources" do
    subject(:sources) { described_class.sources }

    it "puts every source under a sub-plugin of the integrations plugin" do
      expect(sources.map { |source| PluginCatalog.find(source.plugin_key) }).to all(have_attributes(parent: :integrations))
    end

    it "gives every source watcher classes that exist" do
      expect(sources.flat_map(&:watchers).map(&:constantize)).to be_present
    end

    it "gives every source followable event types that are integration events" do
      event_types = sources.flat_map(&:event_types)

      expect(event_types.map(&:constantize)).to be_present.and all(be < Integrations::Event)
    end

    it "defaults each source to a subset of its own event types" do
      expect(sources).to all(satisfy { |source| (source.default_event_types - source.event_types).empty? })
    end

    it "gives every source template tokens" do
      expect(sources.map(&:template_tokens)).to all(be_present)
    end
  end

  describe ".source" do
    it "finds a source by plugin key" do
      expect(described_class.source(:steam)).to eq(Feeds::Steam)
    end

    it "raises for an unknown plugin key" do
      expect { described_class.source(:nope) }.to raise_error(KeyError)
    end
  end

  describe ".source_for_watcher" do
    it "finds the source of a watcher" do
      expect(described_class.source_for_watcher("Integrations::Steam::NewsWatcher")).to eq(Feeds::Steam)
    end
  end
end
