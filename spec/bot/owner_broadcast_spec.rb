# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::OwnerBroadcast do
  describe ".call" do
    subject(:result) { described_class.call(bots:, content: "hello owners") }

    let(:bots) { [shard_one, shard_two] }
    let(:shard_one) { double("shard_one", servers: {1 => server(10), 2 => server(20)}) }
    let(:shard_two) { double("shard_two", servers: {3 => server(10), 4 => server(30)}) }
    let(:channel) { double("channel") }

    def server(owner_id)
      double("server", owner: double("owner", id: owner_id))
    end

    before do
      allow(shard_one).to receive(:pm_channel).and_return(channel)
      allow(Bot::Discord::Components).to receive(:send_to)
    end

    it "counts every server across all shards" do
      expect(result.server_count).to eq(4)
    end

    it "dedupes owners across shards" do
      expect(result.owner_count).to eq(3)
    end

    it "DMs each unique owner once, through one shard's REST" do
      expect(shard_one).to receive(:pm_channel).with(10).once.and_return(channel)
      expect(shard_one).to receive(:pm_channel).with(20).once.and_return(channel)
      expect(shard_one).to receive(:pm_channel).with(30).once.and_return(channel)
      result
    end

    it "sends a components-v2 message with the content and a footer below a separator" do
      expect(Bot::Discord::Components).to receive(:send_to).at_least(:once) do |_channel, rendered, **options|
        expect(rendered[:flags]).to eq(Bot::Discord::Components::COMPONENTS_V2)
        blocks = rendered[:components].first[:components]
        expect(blocks.map { |block| block[:type] }).to include(Bot::Discord::Components::SEPARATOR)
        body = blocks.filter_map { |block| block[:content] }
        expect(body).to include("hello owners")
        expect(body.join).to include("-# ").and include("you own at least one server")
      end
      result
    end

    it "passes a labelled push-notification subject carrying the content" do
      expect(Bot::Discord::Components).to receive(:send_to).at_least(:once).with(channel, anything, subject: "New shrkbot announcement: hello owners")
      result
    end

    it "reports how many were sent" do
      expect(result.sent).to eq(3)
    end

    context "when a DM fails" do
      before do
        allow(shard_one).to receive(:pm_channel).with(20).and_raise("403 cannot DM")
      end

      it "skips it and still reports the rest" do
        expect(result.sent).to eq(2)
        expect(result.owner_count).to eq(3)
      end
    end

    context "when a server's owner can't be resolved" do
      let(:shard_two) { double("shard_two", servers: {3 => double("server", owner: nil)}) }

      it "excludes it from the owner count" do
        expect(result.owner_count).to eq(2)
      end
    end
  end
end
