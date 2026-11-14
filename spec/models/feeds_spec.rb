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

    it "gives every source template tokens" do
      expect(sources.map(&:template_tokens)).to all(be_present)
    end

    it "gives every source notification tokens with the title and a default text per event type" do
      expect(sources).to all(satisfy { |source| source.notification_tokens.include?("title") && source.event_types.all? { |type| source.default_notification(type).present? } })
    end

    it "gives every source a follow-cap message" do
      expect(sources.map { |source| "operations.feeds.subscriptions.cap.#{source.plugin_key}" }).to all(satisfy { |key| I18n.exists?(key) })
    end

    it "gives every source its settings contract" do
      expect(sources).to all(respond_to(:tokens_for, :settings_association, :role_id_for, :accepts?, :post_type, :announced_types))
    end

    it "gives every source an announcement builder" do
      expect(sources).to all(respond_to(:announcement, :retract?, :revive?))
    end

    it "gives Steam the app lookup and casts its languages to an array" do
      settings = Feeds::Steam.settings_from(ActionController::Parameters.new(role_id: "1", body_length: "300", languages: "english").permit!)

      expect([Feeds::Steam.lookup_param, settings[:languages]]).to eq([:app, ["english"]])
    end

    it "gives Twitch categories as values and drops unpermitted settings" do
      category = {"id" => "509658", "name" => "Just Chatting"}
      params = ActionController::Parameters.new(show_viewers: "1", admin: "1", categories: [Feeds::Twitch::CategoryValue.dump(category)]).permit!

      expect(Feeds::Twitch.settings_from(params)).to eq({show_viewers: "1", categories: [category]})
    end
  end

  describe ".source" do
    it "finds a source by plugin key" do
      expect(described_class.source(:steam)).to eq(Feeds::Steam)
    end

    it "finds the Twitch source" do
      expect(described_class.source(:twitch)).to eq(Feeds::Twitch)
    end

    it "raises for an unknown plugin key" do
      expect { described_class.source(:nope) }.to raise_error(KeyError)
    end
  end

  describe ".source_for_watcher" do
    it "finds the source of a watcher" do
      expect(described_class.source_for_watcher("Integrations::Steam::NewsWatcher")).to eq(Feeds::Steam)
    end

    it "finds the source of a Twitch watcher" do
      expect(described_class.source_for_watcher("Integrations::Twitch::ChannelWatcher")).to eq(Feeds::Twitch)
    end
  end
end
