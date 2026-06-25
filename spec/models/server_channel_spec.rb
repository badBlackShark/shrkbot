# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServerChannel do
  describe "primary key" do
    subject(:id) { create(:server_channel).id }

    it "generates a prefixed-uuid" do
      expect(id).to match(/\Asch_\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
    end
  end

  describe "discord_id uniqueness" do
    subject(:duplicate) { build(:server_channel, server_configuration: server, discord_id: 555) }

    let(:server) { create(:server_configuration) }

    before do
      create(:server_channel, server_configuration: server, discord_id: 555)
    end

    it "forbids the same discord_id twice within one server" do
      expect(duplicate).not_to be_valid
    end

    it "allows the same discord_id on a different server" do
      expect(build(:server_channel, discord_id: 555)).to be_valid
    end
  end

  describe ".text" do
    subject(:names) { ServerChannel.text.pluck(:name) }

    let(:server) { create(:server_configuration) }

    before do
      create(:server_channel, server_configuration: server, name: "general", channel_type: 0)
      create(:server_channel, server_configuration: server, name: "announcements", channel_type: 5)
      create(:server_channel, server_configuration: server, name: "lounge", channel_type: 2)
    end

    it "returns only text-capable channels, ordered by name" do
      expect(names).to eq(%w[announcements general])
    end
  end

  describe "#everyone_visible?" do
    subject(:visible) { channel.everyone_visible? }

    let(:server) { create(:server_configuration, discord_id: 42) }
    let(:channel) { create(:server_channel, server_configuration: server) }

    context "with no @everyone overwrite" do
      it { is_expected.to be(true) }
    end

    context "when @everyone is denied VIEW_CHANNEL" do
      before do
        create(:channel_overwrite, server_channel: channel, target_id: 42, deny: ServerChannel::VIEW_CHANNEL)
      end

      it { is_expected.to be(false) }
    end

    context "when @everyone has an overwrite that does not touch VIEW_CHANNEL" do
      before do
        create(:channel_overwrite, server_channel: channel, target_id: 42, deny: 0)
      end

      it { is_expected.to be(true) }
    end

    context "when a non-@everyone role is denied VIEW_CHANNEL" do
      before do
        create(:channel_overwrite, server_channel: channel, target_id: 999, deny: ServerChannel::VIEW_CHANNEL)
      end

      it { is_expected.to be(true) }
    end
  end

  describe "#channel_overwrites" do
    subject(:destroy_channel) { channel.destroy }

    let(:channel) { create(:server_channel) }

    before do
      create(:channel_overwrite, server_channel: channel)
    end

    it "cascades deletion to its overwrites" do
      expect { destroy_channel }.to change(ChannelOverwrite, :count).by(-1)
    end
  end
end
