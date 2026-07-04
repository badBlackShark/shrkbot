# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServerDashboard do
  let(:target_id) { 900_000_001 }
  let(:other_id) { 900_000_002 }
  let(:cached_ids) { [] }

  let(:target_guild) do
    instance_double("Discord::Guild", id: target_id, manageable?: true, member_count: 100)
  end
  let(:other_guild) do
    instance_double("Discord::Guild", id: other_id, manageable?: true, member_count: 50)
  end

  subject(:result) do
    described_class.new(
      discord_token: "tok",
      target_id:,
      cached_ids:
    ).resolve
  end

  context "when Discord is reachable and the target guild is manageable" do
    let!(:config) { create(:server_configuration, discord_id: target_id) }
    let!(:other_config) { create(:server_configuration, discord_id: other_id) }

    before do
      allow(Discord::UserGuilds).to receive(:call).with("tok").and_return([target_guild, other_guild])
    end

    it "returns a Result with the correct guild" do
      expect(result.guild).to eq(target_guild)
    end

    it "returns a Result with the correct server_configuration" do
      expect(result.server_configuration).to eq(config)
    end

    it "returns configured_guilds containing both manageable configured guilds" do
      expect(result.configured_guilds).to contain_exactly(target_guild, other_guild)
    end

    it "returns configured_ids for all configured manageable guilds" do
      expect(result.configured_ids).to contain_exactly(target_id, other_id)
    end
  end

  context "when target guild is not among manageable guilds" do
    let!(:config) { create(:server_configuration, discord_id: target_id) }
    let(:other_guild_only) do
      instance_double("Discord::Guild", id: other_id, manageable?: true, member_count: 50)
    end

    before do
      allow(Discord::UserGuilds).to receive(:call).with("tok").and_return([other_guild_only])
    end

    it "returns nil" do
      expect(result).to be_nil
    end
  end

  context "when Discord::UserGuilds::Unauthorized is raised" do
    before do
      allow(Discord::UserGuilds).to receive(:call).and_raise(Discord::UserGuilds::Unauthorized, "token rejected")
    end

    it "propagates the error" do
      expect { result }.to raise_error(Discord::UserGuilds::Unauthorized)
    end
  end

  context "when Discord::UserGuilds::Error is raised and cache hits" do
    let(:cached_ids) { [target_id, other_id] }
    let!(:target_config) { create(:server_configuration, discord_id: target_id, name: "Dev Refuge", member_count: 100) }
    let!(:other_config) { create(:server_configuration, discord_id: other_id, name: "Other Server", member_count: 50) }

    before do
      allow(Discord::UserGuilds).to receive(:call).and_raise(Discord::UserGuilds::Error, "timeout")
    end

    it "returns a Result from the cache" do
      expect(result).to be_a(ServerDashboard::Result)
    end

    it "returns the correct server_configuration from cache" do
      expect(result.server_configuration).to eq(target_config)
    end

    it "returns configured_ids from the cached_ids" do
      expect(result.configured_ids).to eq(cached_ids)
    end
  end

  context "when Discord::UserGuilds::Error is raised and cache misses" do
    let(:cached_ids) { [] }

    before do
      allow(Discord::UserGuilds).to receive(:call).and_raise(Discord::UserGuilds::Error, "timeout")
    end

    it "re-raises the error" do
      expect { result }.to raise_error(Discord::UserGuilds::Error)
    end
  end
end
