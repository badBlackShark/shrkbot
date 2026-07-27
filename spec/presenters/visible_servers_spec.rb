# frozen_string_literal: true

require "rails_helper"

RSpec.describe VisibleServers do
  include ActiveSupport::Testing::TimeHelpers

  describe ".for" do
    subject(:guilds) { described_class.for("tok", discord_id) }

    let(:discord_id) { 700_000_001 }
    let(:memory) { ActiveSupport::Cache::MemoryStore.new }

    let(:manageable_guild) do
      Bot::Discord::Guild.new(id: 1, name: "Manageable", owner: true, permissions: 0, icon: nil, member_count: 50)
    end
    let(:administered_guild) do
      Bot::Discord::Guild.new(id: 2, name: "Administered", owner: false, permissions: 0, icon: nil, member_count: 200)
    end
    let(:unrelated_guild) do
      Bot::Discord::Guild.new(id: 3, name: "Unrelated", owner: false, permissions: 0, icon: nil, member_count: 30)
    end
    let(:large_manageable_guild) do
      Bot::Discord::Guild.new(id: 4, name: "Large Manageable", owner: true, permissions: 0, icon: nil, member_count: 500)
    end

    before do
      allow(Rails).to receive(:cache).and_return(memory)
      allow(Bot::Discord::UserGuilds).to receive(:call).and_return(
        [manageable_guild, administered_guild, unrelated_guild, large_manageable_guild]
      )
      allow(TwilightStruggle::AdministeredServers).to receive(:discord_ids_for).and_return(Set[2])
    end

    it "always returns manageable guilds" do
      expect(guilds).to include(manageable_guild, large_manageable_guild)
    end

    it "returns a non-manageable guild administered through a tournament admin row" do
      expect(guilds).to include(administered_guild)
    end

    it "drops a non-manageable, non-administered guild" do
      expect(guilds).not_to include(unrelated_guild)
    end

    it "sorts by member_count descending" do
      expect(guilds.map(&:id)).to eq([4, 2, 1])
    end

    it "hits Discord only once for repeated calls within the TTL" do
      3.times { described_class.for("tok", discord_id) }
      expect(Bot::Discord::UserGuilds).to have_received(:call).once
    end

    it "refetches after the TTL expires" do
      described_class.for("tok", discord_id)
      travel(described_class::CACHE_TTL + 1.second) do
        described_class.for("tok", discord_id)
      end
      expect(Bot::Discord::UserGuilds).to have_received(:call).twice
    end

    it "caches per token" do
      described_class.for("tok", discord_id)
      described_class.for("other", discord_id)
      expect(Bot::Discord::UserGuilds).to have_received(:call).with("tok").once
      expect(Bot::Discord::UserGuilds).to have_received(:call).with("other").once
    end
  end
end
