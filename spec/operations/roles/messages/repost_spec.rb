require "rails_helper"

RSpec.describe Ops::Roles::Messages::Repost do
  subject(:result) { described_class.call(bot: bot, role_set: set) }

  let(:bot) { double("bot") }
  let(:channel) { double("channel") }
  let(:setting) { create(:role_setting, channel_id: 555) }

  context "when the set already has a posted message" do
    let(:set) { create(:role_set, role_setting: setting, message_id: 111) }
    let(:old_message) { double("old_message") }

    before do
      allow(bot).to receive(:channel).with(555).and_return(channel)
      allow(channel).to receive(:load_message).with(111).and_return(old_message)
      allow(old_message).to receive(:delete)
      allow(channel).to receive(:send_message).and_return(double(id: 222))
    end

    it "deletes the stale message" do
      expect(old_message).to receive(:delete)
      result
    end

    it "posts a fresh message and stores its id" do
      result
      expect(set.reload.message_id).to eq(222)
    end

    it "succeeds" do
      expect(result).to be_success
    end
  end

  context "when the stale message is already gone" do
    let(:set) { create(:role_set, role_setting: setting, message_id: 111) }

    before do
      allow(bot).to receive(:channel).with(555).and_return(channel)
      allow(channel).to receive(:load_message).with(111).and_return(nil)
      allow(channel).to receive(:send_message).and_return(double(id: 222))
    end

    it "reposts without raising" do
      expect { result }.not_to raise_error
      expect(set.reload.message_id).to eq(222)
    end
  end

  context "when deleting the stale message raises" do
    let(:set) { create(:role_set, role_setting: setting, message_id: 111) }
    let(:old_message) { double("old_message") }

    before do
      allow(bot).to receive(:channel).with(555).and_return(channel)
      allow(channel).to receive(:load_message).with(111).and_return(old_message)
      allow(old_message).to receive(:delete).and_raise("404")
      allow(channel).to receive(:send_message).and_return(double(id: 222))
    end

    it "swallows the delete failure and still reposts" do
      result
      expect(set.reload.message_id).to eq(222)
    end
  end

  context "when the set has no message yet" do
    let(:set) { create(:role_set, role_setting: setting, message_id: nil) }

    before do
      allow(bot).to receive(:channel).with(555).and_return(channel)
      allow(channel).to receive(:send_message).and_return(double(id: 222))
    end

    it "posts without trying to load a stale message" do
      expect(channel).not_to receive(:load_message)
      result
      expect(set.reload.message_id).to eq(222)
    end
  end

  context "when the channel can't be resolved" do
    let(:set) { create(:role_set, role_setting: setting, message_id: 111) }

    before do
      allow(bot).to receive(:channel).with(555).and_return(nil)
    end

    it "fails and leaves no message id" do
      expect(result).to be_failure
      expect(set.reload.message_id).to be_nil
    end
  end
end
