# frozen_string_literal: true

require "rails_helper"

RSpec.describe CachedDashboard do
  let(:discord_id) { 900_000_001 }
  let(:other_id) { 900_000_002 }
  let!(:config) { create(:server_configuration, discord_id:, name: "Dev Refuge", member_count: 50) }
  let!(:other_config) { create(:server_configuration, discord_id: other_id, name: "Other Server", member_count: 100) }

  describe ".for" do
    subject(:dashboard) do
      described_class.for(
        discord_id:,
        manageable_ids: [discord_id, other_id]
      )
    end

    it "returns a dashboard for the given discord_id" do
      expect(dashboard).to be_a(described_class)
    end

    it "sets server_configuration to the matching config" do
      expect(dashboard.server_configuration).to eq(config)
    end

    context "when the target id is not in manageable_ids" do
      subject(:dashboard) do
        described_class.for(
          discord_id: 999_999_999,
          manageable_ids: [discord_id, other_id]
        )
      end

      it { is_expected.to be_nil }
    end

    context "when the matching config has a nil name" do
      before { config.update!(name: nil) }

      it { is_expected.to be_nil }
    end
  end

  describe "#guild" do
    subject(:guild) do
      described_class.for(
        discord_id:,
        manageable_ids: [discord_id, other_id]
      ).guild
    end

    it "returns a CachedGuild for the target server" do
      expect(guild).to be_a(CachedGuild)
      expect(guild.id).to eq(discord_id)
    end
  end

  describe "#configured_guilds" do
    subject(:guilds) do
      described_class.for(
        discord_id:,
        manageable_ids: [discord_id, other_id]
      ).configured_guilds
    end

    it "returns CachedGuild instances for each manageable config" do
      expect(guilds).to all(be_a(CachedGuild))
    end

    it "orders guilds by member_count descending" do
      expect(guilds.map(&:id)).to eq([other_id, discord_id])
    end
  end

  describe "#plugin_counts" do
    subject(:counts) do
      described_class.for(
        discord_id:,
        manageable_ids: [discord_id, other_id]
      ).plugin_counts
    end

    let(:plugin) { create(:plugin) }

    before do
      create(:plugin_activation, server_configuration: config, plugin:, enabled: true)
    end

    it "delegates to PluginActivation.enabled_counts_for with config discord_ids" do
      expect(counts).to eq({discord_id => 1})
    end
  end
end
