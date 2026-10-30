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

  describe ".active" do
    subject(:active) { described_class.active }

    let(:server_configuration) { create(:server_configuration) }
    let!(:subscription) { create(:feed_subscription, server_configuration:) }
    let(:integrations_enabled) { true }
    let(:steam_enabled) { true }

    before do
      integrations_activation = create(:plugin_activation, server_configuration:, plugin: create(:plugin, key: "integrations"), enabled: true)
      create(:plugin_activation, server_configuration:, plugin: create(:plugin, key: "steam"), enabled: steam_enabled)
      integrations_activation.update_column(:enabled, integrations_enabled)
    end

    context "with integrations and steam enabled on a real server" do
      it "includes the subscription" do
        expect(active).to contain_exactly(subscription)
      end
    end

    context "with integrations disabled" do
      let(:integrations_enabled) { false }

      it { is_expected.to be_empty }
    end

    context "with steam disabled" do
      let(:steam_enabled) { false }

      it { is_expected.to be_empty }
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

    context "with another server that has only integrations enabled" do
      let!(:other) { create(:feed_subscription) }

      before do
        create(:plugin_activation, server_configuration: other.server_configuration, plugin: Plugin.find_by!(key: "integrations"), enabled: true)
      end

      it "includes only the fully enabled one" do
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
