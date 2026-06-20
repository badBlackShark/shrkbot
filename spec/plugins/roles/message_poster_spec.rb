require "rails_helper"

RSpec.describe Roles::MessagePoster do
  subject(:post) { described_class.post(bot, set) }

  let(:bot) { double("bot") }
  let(:channel) { double("channel") }
  let(:setting) { create(:role_setting, channel_id: 555) }

  context "when the set has no message yet" do
    let(:set) { create(:role_set, role_setting: setting, channel_override: nil, message_id: nil) }

    before do
      allow(bot).to receive(:channel).with(555).and_return(channel)
      allow(channel).to receive(:send_message).and_return(double(id: 98765))
    end

    it "posts and stores the returned message id" do
      post
      expect(set.reload.message_id).to eq(98765)
    end

    it "sends with the components-v2 flag so the container is accepted" do
      expect(channel).to receive(:send_message)
        .with(nil, false, nil, nil, nil, nil, anything, Discord::Components::COMPONENTS_V2)
        .and_return(double(id: 1))
      post
    end
  end

  context "when the set already has a message" do
    let(:set) { create(:role_set, role_setting: setting, message_id: 111) }
    let(:message) { double("message") }

    before do
      allow(bot).to receive(:channel).with(555).and_return(channel)
      allow(channel).to receive(:load_message).with(111).and_return(message)
    end

    it "edits the existing message rather than reposting" do
      expect(message).to receive(:edit)
      post
    end

    it "edits with the components-v2 flag" do
      expect(message).to receive(:edit).with(nil, nil, anything, Discord::Components::COMPONENTS_V2)
      post
    end
  end

  context "when a channel override is set" do
    let(:set) { create(:role_set, role_setting: setting, channel_override: 999, message_id: nil) }

    before do
      allow(bot).to receive(:channel).with(999).and_return(channel)
      allow(channel).to receive(:send_message).and_return(double(id: 1))
    end

    it "posts to the override, not the default channel" do
      post
      expect(bot).to have_received(:channel).with(999)
    end
  end

  context "when the stored message has since been deleted" do
    let(:set) { create(:role_set, role_setting: setting, message_id: 111) }

    before do
      allow(bot).to receive(:channel).with(555).and_return(channel)
      allow(channel).to receive(:load_message).with(111).and_return(nil)
    end

    it "skips the edit without raising" do
      expect { post }.not_to raise_error
    end
  end

  context "when the bot can't resolve the channel" do
    let(:set) { create(:role_set, role_setting: setting, channel_override: nil, message_id: nil) }

    before do
      allow(bot).to receive(:channel).with(555).and_return(nil)
    end

    it "does nothing" do
      post
      expect(set.reload.message_id).to be_nil
    end
  end

  context "when there is no channel to post in" do
    let(:setting) { create(:role_setting, channel_id: nil) }
    let(:set) { create(:role_set, role_setting: setting, channel_override: nil) }

    it "does nothing" do
      expect(bot).not_to receive(:channel)
      post
    end
  end
end
