# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe Lfg::DoneLooking do
  subject(:handle) { described_class.new(event).handle }

  let(:custom_id) { Lfg::CustomId.done(1, 0, 55) }
  let(:uid) { 1 }
  let(:channel) { double("channel", id: 20) }
  let(:message) { double("message", id: 500) }
  let(:user) { double("user", id: uid) }
  let(:member) { double("member", permission?: false) }
  let(:server) { double("server", member: member) }
  let(:event) do
    double(
      "event",
      custom_id:,
      user:,
      channel:,
      message:,
      server:,
      defer: nil,
      edit_response: nil,
      respond: nil
    )
  end

  before do
    allow(Bot::Config).to receive(:token).and_return("tok")
    allow(Discordrb::API::Channel).to receive(:delete_message)
  end

  context "when the requester is the creator" do
    let(:uid) { 1 }
    let!(:lfg_message) { create(:lfg_message, message_id: 500, notify_reply_id: 600, start_ping_id: 601) }

    it "defers ephemerally" do
      expect(event).to receive(:defer).with(ephemeral: true)
      handle
    end

    it "deletes the notify reply, the start ping and the post" do
      handle
      expect(Discordrb::API::Channel).to have_received(:delete_message).with("Bot tok", 20, 600)
      expect(Discordrb::API::Channel).to have_received(:delete_message).with("Bot tok", 20, 601)
      expect(Discordrb::API::Channel).to have_received(:delete_message).with("Bot tok", 20, 500)
    end

    it "destroys the message row" do
      expect(Ops::Lfg::Message::Destroy).to receive(:call).with(message: lfg_message)
      handle
    end

    it "edits the response to confirm closure" do
      expect(event).to receive(:edit_response).with(content: "Looking for Game closed.")
      handle
    end
  end

  context "when the requester is not the creator and cannot manage messages" do
    let(:uid) { 2 }

    it "responds as unauthorized" do
      expect(event).to receive(:respond).with(
        content: "Only the poster or a mod can close this Looking for Game.",
        ephemeral: true
      )
      handle
    end

    it "does not defer or delete anything" do
      expect(event).not_to receive(:defer)
      handle
      expect(Discordrb::API::Channel).not_to have_received(:delete_message)
    end
  end

  context "when the requester is not the creator but can manage messages" do
    let(:uid) { 2 }
    let(:member) { double("member", permission?: true) }
    let!(:lfg_message) { create(:lfg_message, message_id: 500, notify_reply_id: 600, start_ping_id: 601) }

    it "is authorized to close" do
      expect(event).to receive(:defer).with(ephemeral: true)
      handle
    end

    it "deletes the notify reply, the start ping and the post" do
      handle
      expect(Discordrb::API::Channel).to have_received(:delete_message).with("Bot tok", 20, 600)
      expect(Discordrb::API::Channel).to have_received(:delete_message).with("Bot tok", 20, 601)
      expect(Discordrb::API::Channel).to have_received(:delete_message).with("Bot tok", 20, 500)
    end
  end

  context "when the requester is not the creator and the member cannot be resolved" do
    let(:uid) { 2 }
    let(:server) { nil }

    it "responds as unauthorized" do
      expect(event).to receive(:respond).with(
        content: "Only the poster or a mod can close this Looking for Game.",
        ephemeral: true
      )
      handle
    end
  end

  context "when the message row has no notify reply or start ping" do
    let!(:lfg_message) { create(:lfg_message, message_id: 500, notify_reply_id: nil, start_ping_id: nil) }

    it "deletes only the post" do
      handle
      expect(Discordrb::API::Channel).to have_received(:delete_message).with("Bot tok", 20, 500).once
    end

    it "still destroys the message row" do
      expect(Ops::Lfg::Message::Destroy).to receive(:call).with(message: lfg_message)
      handle
    end
  end

  context "when there is no message row" do
    it "deletes only the post" do
      handle
      expect(Discordrb::API::Channel).to have_received(:delete_message).with("Bot tok", 20, 500).once
    end

    it "does not attempt to destroy a row" do
      expect(Ops::Lfg::Message::Destroy).not_to receive(:call)
      handle
    end
  end

  context "when deleting a message fails" do
    let!(:lfg_message) { create(:lfg_message, message_id: 500, notify_reply_id: 600, start_ping_id: 601) }

    before do
      allow(Discordrb::API::Channel).to receive(:delete_message)
        .and_raise(Discordrb::Errors::UnknownMessage.new("Unknown Message"))
    end

    it "swallows the error" do
      expect { handle }.not_to raise_error
    end
  end
end
