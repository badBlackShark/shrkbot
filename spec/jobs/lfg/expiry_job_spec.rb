# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe Lfg::ExpiryJob do
  subject(:perform) { described_class.perform_now(20, 500) }

  before do
    allow(Bot::Config).to receive(:token).and_return("tok")
    allow(Discordrb::API::Channel).to receive(:delete_message)
  end

  context "when the row has a notify reply and a start ping" do
    let!(:lfg_message) { create(:lfg_message, message_id: 500, notify_reply_id: 700, start_ping_id: 800) }

    it "deletes the notify reply, the start ping and the post" do
      perform
      expect(Discordrb::API::Channel).to have_received(:delete_message).with("Bot tok", 20, 700)
      expect(Discordrb::API::Channel).to have_received(:delete_message).with("Bot tok", 20, 800)
      expect(Discordrb::API::Channel).to have_received(:delete_message).with("Bot tok", 20, 500)
    end

    it "destroys the message row" do
      expect(Ops::Lfg::Message::Destroy).to receive(:call).with(message: lfg_message)
      perform
    end
  end

  context "when the row has no notify reply or start ping" do
    let!(:lfg_message) { create(:lfg_message, message_id: 500, notify_reply_id: nil, start_ping_id: nil) }

    it "deletes only the post" do
      perform
      expect(Discordrb::API::Channel).to have_received(:delete_message).with("Bot tok", 20, 500).once
    end
  end

  context "when there is no row" do
    it "deletes only the post" do
      perform
      expect(Discordrb::API::Channel).to have_received(:delete_message).with("Bot tok", 20, 500).once
    end

    it "does not attempt to destroy a row" do
      expect(Ops::Lfg::Message::Destroy).not_to receive(:call)
      perform
    end
  end

  context "when deleting a message fails" do
    let!(:lfg_message) { create(:lfg_message, message_id: 500, notify_reply_id: 700, start_ping_id: 800) }

    before do
      allow(Discordrb::API::Channel).to receive(:delete_message)
        .and_raise(Discordrb::Errors::UnknownMessage.new("Unknown Message"))
    end

    it "does not raise" do
      expect { perform }.not_to raise_error
    end
  end
end
