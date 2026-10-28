# frozen_string_literal: true

require "rails_helper"

RSpec.describe Finders::Feeds::SourceSubscriptions do
  subject(:subscriptions) { described_class.call(server_configuration:, plugin_key: :steam) }

  let(:server_configuration) { create(:server_configuration) }
  let(:other_server) { create(:server_configuration) }
  let(:zelda) { create(:integration_watch, name: "Zelda") }
  let(:apex) { create(:integration_watch, name: "Apex") }
  let(:mario) { create(:integration_watch, name: "Mario") }
  let(:other_source) { create(:integration_watch, watcher: "Integrations::Other::NewsWatcher", name: "Aardvark") }

  let!(:zelda_subscription) { create(:feed_subscription, server_configuration:, watch: zelda) }
  let!(:mario_subscription) { create(:feed_subscription, server_configuration:, watch: mario) }
  let!(:other_source_subscription) { create(:feed_subscription, server_configuration:, watch: other_source) }
  let!(:apex_subscription) { create(:feed_subscription, server_configuration:, watch: apex) }

  before do
    create(:feed_subscription, server_configuration: other_server, watch: apex)
  end

  context "when several watchers feed the same plugin" do
    before do
      stub_const("Feeds::SOURCE_PLUGINS", Feeds::SOURCE_PLUGINS.merge("Integrations::Other::NewsWatcher" => :steam))
    end

    it "returns the subscriptions of every watcher" do
      expect(subscriptions).to eq([other_source_subscription, apex_subscription, mario_subscription, zelda_subscription])
    end
  end

  it "returns only this server's subscriptions on the source, ordered by game name" do
    expect(subscriptions).to eq([apex_subscription, mario_subscription, zelda_subscription])
  end
end
