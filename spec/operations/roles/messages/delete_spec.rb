# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Roles::Messages::Delete do
  subject(:result) { described_class.call(bot:, channel_id: 111, message_id: 222) }

  let(:bot) { double("bot") }
  let(:channel) { double("channel") }
  let(:message) { double("message") }

  context "when the channel and message both exist" do
    before do
      allow(bot).to receive(:channel).with(111).and_return(channel)
      allow(channel).to receive(:load_message).with(222).and_return(message)
      allow(message).to receive(:delete)
    end

    it "deletes the message" do
      expect(message).to receive(:delete)
      result
    end

    it "succeeds" do
      expect(result).to be_success
    end
  end

  context "when the channel cannot be resolved" do
    before do
      allow(bot).to receive(:channel).with(111).and_return(nil)
    end

    it "succeeds without raising" do
      expect { result }.not_to raise_error
      expect(result).to be_success
    end
  end

  context "when load_message returns nil" do
    before do
      allow(bot).to receive(:channel).with(111).and_return(channel)
      allow(channel).to receive(:load_message).with(222).and_return(nil)
    end

    it "succeeds without raising" do
      expect { result }.not_to raise_error
      expect(result).to be_success
    end
  end

  context "when delete raises" do
    before do
      allow(bot).to receive(:channel).with(111).and_return(channel)
      allow(channel).to receive(:load_message).with(222).and_return(message)
      allow(message).to receive(:delete).and_raise("Discord 404")
    end

    it "swallows the error and succeeds" do
      expect { result }.not_to raise_error
      expect(result).to be_success
    end
  end
end
