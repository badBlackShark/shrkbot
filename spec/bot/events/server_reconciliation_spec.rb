# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::ServerReconciliation do
  subject(:handle) { described_class.new(event).handle }

  let(:present_id) { 111 }
  let(:bot) { double("bot", servers: {present_id => double("server")}, shard_key: nil) }
  let(:event) { double("event", bot:) }

  let(:op) { Ops::ServerConfiguration::Destroy }

  context "when a config's guild is present in bot.servers" do
    let!(:config) { create(:server_configuration, discord_id: present_id) }

    it "does not check membership" do
      expect(Bot::Discord::GuildMembership).not_to receive(:member?)
      handle
    end

    it "does not destroy the config" do
      expect(op).not_to receive(:call)
      handle
    end
  end

  context "when a config's guild is absent from bot.servers" do
    let(:absent_id) { 999 }
    let!(:config) { create(:server_configuration, discord_id: absent_id) }

    context "when member? returns false (bot was kicked)" do
      before do
        allow(Bot::Discord::GuildMembership).to receive(:member?).with(absent_id).and_return(false)
      end

      it "calls the destroy operation" do
        expect(op).to receive(:call).with(server_configuration: config)
        handle
      end
    end

    context "when member? returns true (cache was incomplete)" do
      before do
        allow(Bot::Discord::GuildMembership).to receive(:member?).with(absent_id).and_return(true)
      end

      it "does not destroy the config" do
        expect(op).not_to receive(:call)
        handle
      end
    end
  end

  context "when sharded" do
    let(:shard_0_id) { 2 << 22 }
    let(:shard_1_id) { 1 << 22 }

    let(:bot) { double("bot", servers: {}, shard_key: [0, 2]) }

    let!(:own_config) { create(:server_configuration, discord_id: shard_0_id) }
    let!(:other_config) { create(:server_configuration, discord_id: shard_1_id) }

    before do
      allow(Bot::Discord::GuildMembership).to receive(:member?).with(shard_0_id).and_return(false)
    end

    it "checks membership only for configs on this shard" do
      expect(Bot::Discord::GuildMembership).not_to receive(:member?).with(shard_1_id)
      handle
    end

    it "destroys only the config on this shard" do
      expect(op).to receive(:call).with(server_configuration: own_config)
      expect(op).not_to receive(:call).with(server_configuration: other_config)
      handle
    end
  end
end
