# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Roles::Messages::Post do
  subject(:result) { described_class.call(bot:, role_set: set) }

  let(:bot) { double("bot") }
  let(:channel) { double("channel") }
  let(:setting) { create(:role_setting, channel_id: 555) }

  context "when the set has a channel and posting succeeds" do
    let(:set) { create(:role_set, role_setting: setting, message_id: nil) }

    before do
      allow(bot).to receive(:channel).with(555).and_return(channel)
      allow(channel).to receive(:send_message).and_return(double(id: 888))
    end

    it "posts the message via MessagePoster" do
      result
      expect(set.reload.message_id).to eq(888)
    end

    it "succeeds" do
      expect(result).to be_success
    end
  end

  context "when MessagePoster cannot post (message_id stays nil)" do
    let(:set) { create(:role_set, role_setting: setting, message_id: nil) }

    before do
      allow(bot).to receive(:channel).with(555).and_return(nil)
    end

    it "fails" do
      expect(result).to be_failure
    end

    it "returns an error message" do
      expect(result.errors).to be_present
    end
  end

  context "when the set has no channel_id configured" do
    let(:setting_no_channel) { create(:role_setting, channel_id: nil) }
    let(:set) { create(:role_set, role_setting: setting_no_channel, message_id: nil, channel_override: nil) }

    it "succeeds without posting" do
      expect(Roles::MessagePoster).not_to receive(:post)
      expect(result).to be_success
    end
  end
end
