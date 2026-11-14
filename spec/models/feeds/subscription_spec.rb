# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Subscription do
  describe "validations" do
    subject(:subscription) { build(:feed_subscription, server_configuration:, watch:, channel_id:) }

    let(:server_configuration) { create(:server_configuration) }
    let(:watch) { create(:integration_watch) }
    let(:channel_id) { 555_000 }

    it { is_expected.to be_valid }

    context "without a channel" do
      let(:channel_id) { nil }

      it { is_expected.not_to be_valid }
    end

    context "when the server already follows the watch" do
      before do
        create(:feed_subscription, server_configuration:, watch:)
      end

      it { is_expected.not_to be_valid }
    end

    context "when another server follows the watch" do
      before do
        create(:feed_subscription, watch:)
      end

      it { is_expected.to be_valid }
    end
  end

  describe "#settings" do
    subject(:settings) { subscription.settings }

    let(:subscription) { create(:feed_subscription) }

    it "is the source's stored settings row" do
      expect(settings).to eq(Feeds::Steam::Settings.find_by!(subscription:))
    end

    context "without a stored row" do
      before { subscription.steam_settings.delete }

      it "builds none" do
        expect(subscription.reload.settings).to be_nil
      end
    end
  end

  describe "#build_settings" do
    subject(:built) { subscription.build_settings(role_id: 42) }

    let(:subscription) { build(:feed_subscription) }

    it "saves them with the subscription" do
      built
      subscription.save!

      expect(subscription.reload.steam_settings.role_id).to eq(42)
    end
  end

  describe "#channel_for" do
    subject(:channel) { subscription.channel_for(event_type) }

    let(:subscription) { create(:feed_subscription, :twitch, channel_id: 555_000) }
    let(:event_type) { "Integrations::Twitch::ClipCreated" }
    let(:own_channel) { nil }

    before do
      create(:feed_subscribed_event, subscription:, event_type: "Integrations::Twitch::ClipCreated", channel_id: own_channel)
      create(:feed_subscribed_event, subscription:, event_type: "Integrations::Twitch::StreamStarted", channel_id: 666_000)
    end

    context "with a channel of its own" do
      let(:event_type) { "Integrations::Twitch::StreamStarted" }

      it { is_expected.to eq(666_000) }
    end

    context "without a channel of its own" do
      it { is_expected.to eq(555_000) }
    end

    context "with an update to a live post" do
      let(:event_type) { "Integrations::Twitch::StreamUpdated" }

      it "goes where the live type goes" do
        expect(channel).to eq(666_000)
      end
    end
  end

  describe ".at_cap?" do
    subject(:at_cap) { described_class.at_cap?(server_configuration, Feeds::Steam) }

    let(:server_configuration) { create(:server_configuration) }

    context "with the cap reached on the source" do
      before { create_list(:feed_subscription, described_class::MAX_PER_SOURCE, server_configuration:) }

      it { is_expected.to be(true) }
    end

    context "with the cap reached on another source only" do
      before do
        create_list(:feed_subscription, described_class::MAX_PER_SOURCE - 1, server_configuration:)
        create_list(:integration_watch, described_class::MAX_PER_SOURCE, watcher: "Integrations::Other::Watcher").each do |watch|
          create(:feed_subscription, server_configuration:, watch:)
        end
      end

      it { is_expected.to be(false) }
    end
  end

  describe ".demanding" do
    subject(:demanding) { described_class.demanding([stream_started]) }

    let(:stream_started) { "Integrations::Twitch::StreamStarted" }
    let!(:following) { create(:feed_subscription, :twitch, :active) }
    let!(:idle) { create(:feed_subscription, :twitch, :active) }
    let!(:inactive) { create(:feed_subscription, :twitch) }

    before do
      create(:feed_subscribed_event, subscription: following, event_type: stream_started)
      create(:feed_subscribed_event, subscription: inactive, event_type: stream_started)
    end

    it "includes only active subscriptions that follow one of the types" do
      expect(demanding).to contain_exactly(following)
    end
  end

  describe ".demanded_types" do
    subject(:demanded_types) { described_class.demanded_types([followed.watch_id, inactive.watch_id]) }

    let(:stream_started) { "Integrations::Twitch::StreamStarted" }
    let!(:followed) { create(:feed_subscription, :twitch, :active) }
    let!(:inactive) { create(:feed_subscription, :twitch) }
    let!(:elsewhere) { create(:feed_subscription, :twitch, :active) }

    before do
      create(:feed_subscribed_event, subscription: followed, event_type: stream_started)
      create(:feed_subscribed_event, subscription: inactive, event_type: stream_started)
      create(:feed_subscribed_event, subscription: elsewhere, event_type: stream_started)
    end

    it "pairs each watch with the types its active subscriptions follow" do
      expect(demanded_types).to contain_exactly([followed.watch_id, stream_started])
    end
  end

  describe ".active" do
    subject(:active) { described_class.active }

    let(:server_configuration) { create(:server_configuration) }
    let!(:subscription) { create(:feed_subscription, server_configuration:) }
    let(:steam_enabled) { true }

    before do
      create(:plugin_activation, server_configuration:, plugin: create(:plugin, key: "steam"), enabled: steam_enabled)
    end

    context "with steam enabled on a real server" do
      it "includes the subscription" do
        expect(active).to contain_exactly(subscription)
      end
    end

    context "with steam disabled" do
      let(:steam_enabled) { false }

      it { is_expected.to be_empty }
    end

    context "with a Twitch subscription" do
      let(:twitch_enabled) { true }
      let!(:twitch_subscription) { create(:feed_subscription, :twitch, server_configuration:) }

      before do
        create(:plugin_activation, server_configuration:, plugin: create(:plugin, key: "twitch"), enabled: twitch_enabled)
      end

      it "includes it next to the Steam one" do
        expect(active).to contain_exactly(subscription, twitch_subscription)
      end

      context "with twitch disabled" do
        let(:twitch_enabled) { false }

        it "leaves it out" do
          expect(active).to contain_exactly(subscription)
        end
      end
    end

    context "on a preview server" do
      let(:server_configuration) { create(:server_configuration, :preview) }

      it { is_expected.to be_empty }
    end

    context "with a watch from a source that has no sub-plugin" do
      let!(:subscription) do
        create(:feed_subscription, server_configuration:, watch: create(:integration_watch, watcher: "Integrations::Other::Watcher"))
      end

      it { is_expected.to be_empty }
    end

    context "with another server that has Steam off" do
      let!(:other) { create(:feed_subscription) }

      before do
        create(:plugin_activation, server_configuration: other.server_configuration, plugin: Plugin.find_by!(key: "steam"), enabled: false)
      end

      it "includes only the one with Steam on" do
        expect(active).to contain_exactly(subscription)
      end
    end

    context "when chained onto another condition" do
      subject(:active) { described_class.where(channel_id: 1).active }

      it "keeps both" do
        expect(active).to be_empty
      end
    end

    context "when chained after a join" do
      subject(:active) { described_class.joins(:server_configuration).active }

      it "includes the subscription" do
        expect(active).to contain_exactly(subscription)
      end
    end
  end
end
