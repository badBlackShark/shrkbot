# frozen_string_literal: true

require "rails_helper"

RSpec.describe ManageableServers do
  describe ".for" do
    subject(:guilds) { described_class.for("tok") }

    let(:manageable_guild) do
      instance_double("Bot::Discord::Guild", manageable?: true, member_count: 50, id: 1)
    end
    let(:unmanageable_guild) do
      instance_double("Bot::Discord::Guild", manageable?: false, member_count: 200, id: 2)
    end
    let(:large_manageable_guild) do
      instance_double("Bot::Discord::Guild", manageable?: true, member_count: 500, id: 3)
    end

    before do
      allow(Bot::Discord::UserGuilds).to receive(:call).with("tok").and_return(
        [manageable_guild, unmanageable_guild, large_manageable_guild]
      )
    end

    it "returns only manageable guilds" do
      expect(guilds).to contain_exactly(manageable_guild, large_manageable_guild)
    end

    it "sorts by member_count descending" do
      expect(guilds.map(&:id)).to eq([3, 1])
    end
  end

  describe ".cached_for" do
    include ActiveSupport::Testing::TimeHelpers

    let(:guild) { Bot::Discord::Guild.new(id: 1, name: "Guild", owner: true, permissions: 0, icon: nil, member_count: 5) }
    let(:memory) { ActiveSupport::Cache::MemoryStore.new }

    before do
      allow(Rails).to receive(:cache).and_return(memory)
      allow(Bot::Discord::UserGuilds).to receive(:call).and_return([guild])
    end

    it "returns the manageable guilds" do
      expect(described_class.cached_for("tok")).to eq([guild])
    end

    it "hits Discord only once for repeated calls within the TTL" do
      3.times { described_class.cached_for("tok") }
      expect(Bot::Discord::UserGuilds).to have_received(:call).once
    end

    it "refetches after the TTL expires" do
      described_class.cached_for("tok")
      travel(described_class::CACHE_TTL + 1.second) do
        described_class.cached_for("tok")
      end
      expect(Bot::Discord::UserGuilds).to have_received(:call).twice
    end

    it "caches per token" do
      described_class.cached_for("tok")
      described_class.cached_for("other")
      expect(Bot::Discord::UserGuilds).to have_received(:call).with("tok").once
      expect(Bot::Discord::UserGuilds).to have_received(:call).with("other").once
    end
  end
end
