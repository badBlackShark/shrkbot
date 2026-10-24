# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Feeds::SubscribedEvents::Resume do
  include ActiveSupport::Testing::TimeHelpers

  subject(:result) { described_class.call(server_configuration: server, plugin_key:) }

  before do
    stub_const("Feeds::SOURCE_PLUGINS", Feeds::SOURCE_PLUGINS.merge("Integrations::Other::Watcher" => :other_source))
    stub_const("Feeds::EVENT_TYPES_BY_SOURCE", Feeds::EVENT_TYPES_BY_SOURCE.merge(other_source: ["Integrations::Steam::PatchNotesPublished"]))
  end

  let(:now) { Time.utc(2026, 10, 23, 12, 0, 0) }
  let(:long_ago) { Time.utc(2026, 10, 1, 12, 0, 0) }
  let(:server) { create(:server_configuration) }
  let(:subscription) { create(:feed_subscription, server_configuration: server) }
  let(:foreign_subscription) { create(:feed_subscription) }
  let(:other_watcher_watch) { create(:integration_watch, watcher: "Integrations::Other::Watcher") }
  let(:other_watcher_subscription) { create(:feed_subscription, server_configuration: server, watch: other_watcher_watch) }
  let!(:steam_follow) { create(:feed_subscribed_event, subscription:, subscribed_since: long_ago) }
  let!(:other_watcher_follow) { create(:feed_subscribed_event, subscription: other_watcher_subscription, subscribed_since: long_ago) }
  let!(:foreign_follow) { create(:feed_subscribed_event, subscription: foreign_subscription, subscribed_since: long_ago) }

  before do
    travel_to(now)
  end

  context "when the feeds plugin is the one enabled" do
    let(:plugin_key) { :feeds }

    it "resets every follow time of the server" do
      result

      expect(Feeds::SubscribedEvent.where(id: [steam_follow, other_watcher_follow]).pluck(:subscribed_since)).to all(eq(now))
    end

    it "leaves other servers alone" do
      result

      expect(foreign_follow.reload.subscribed_since).to eq(long_ago)
    end
  end

  context "when a source plugin is the one enabled" do
    let(:plugin_key) { :steam_news }

    it "resets the follow times on that source's watches only" do
      result

      expect(steam_follow.reload.subscribed_since).to eq(now)
      expect(other_watcher_follow.reload.subscribed_since).to eq(long_ago)
    end

    it "leaves other servers alone" do
      result

      expect(foreign_follow.reload.subscribed_since).to eq(long_ago)
    end
  end

  context "when an unrelated plugin is the one enabled" do
    let(:plugin_key) { :logging }

    it "changes nothing" do
      result

      expect(Feeds::SubscribedEvent.pluck(:subscribed_since)).to all(eq(long_ago))
    end
  end
end
