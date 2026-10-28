# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Subscription do
  describe "validations" do
    subject(:subscription) { build(:feed_subscription, server_configuration:, watch:, channel_id:, body_length:, languages:) }

    let(:server_configuration) { create(:server_configuration) }
    let(:watch) { create(:integration_watch) }
    let(:channel_id) { 555_000 }
    let(:body_length) { "preview" }
    let(:languages) { %w[de en] }

    it { is_expected.to be_valid }

    context "without a channel" do
      let(:channel_id) { nil }

      it { is_expected.not_to be_valid }
    end

    context "with an unknown body length" do
      let(:body_length) { "everything" }

      it { is_expected.not_to be_valid }
    end

    context "with a language the detector cannot produce" do
      let(:languages) { %w[de xx] }

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

  describe "languages normalization" do
    subject(:subscription) { build(:feed_subscription, languages: ["de", "", "de", "en"]) }

    it "stores each language once and drops blanks" do
      expect(subscription.languages).to eq(%w[de en])
    end
  end

  describe "#accepts_language?" do
    subject(:accepted) { build(:feed_subscription, languages:).accepts_language?(language) }

    let(:languages) { %w[de en] }
    let(:language) { "de" }

    context "without a filter" do
      let(:languages) { [] }
      let(:language) { "ru" }

      it { is_expected.to be(true) }
    end

    context "when the language is unknown" do
      let(:language) { nil }

      it { is_expected.to be(true) }
    end

    context "when the language is listed" do
      it { is_expected.to be(true) }
    end

    context "when the language is not listed" do
      let(:language) { "ru" }

      it { is_expected.to be(false) }
    end
  end

  describe "languages check constraint" do
    subject(:save) { subscription.save!(validate: false) }

    let(:subscription) { build(:feed_subscription, languages: Integrations::Language::CODES) }

    it "accepts every code the detector can produce" do
      expect { save }.not_to raise_error
    end
  end

  describe "defaults" do
    subject(:body_length) { subscription.body_length }

    let(:subscription) { create(:feed_subscription) }

    it "previews the body" do
      expect(body_length).to eq("preview")
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
