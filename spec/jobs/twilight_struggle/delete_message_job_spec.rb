# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe TwilightStruggle::DeleteMessageJob do
  subject(:perform) { described_class.perform_now(channel_id, message_id) }

  let(:channel_id) { 111 }
  let(:message_id) { 222 }

  before do
    allow(Bot::Discord::Components).to receive(:delete_message)
  end

  it "deletes the message at the given channel and message ids" do
    perform

    expect(Bot::Discord::Components).to have_received(:delete_message).with(channel_id, message_id)
  end

  context "when the message is already gone" do
    before do
      allow(Bot::Discord::Components).to receive(:delete_message).and_raise(Discordrb::Errors::UnknownMessage.new("gone"))
    end

    it "discards instead of retrying" do
      expect { perform }.not_to raise_error
    end
  end
end
