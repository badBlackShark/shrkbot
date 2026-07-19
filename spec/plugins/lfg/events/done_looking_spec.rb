# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe Lfg::DoneLooking do
  subject(:handle) { described_class.new(event).handle }

  let(:custom_id) { Lfg::CustomId.done(1, 0) }
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

  let(:notify_reply_id) { 600 }

  def message_json(notify_reply_id:)
    rendered = Lfg::PostMessage.render(
      role_id: 55,
      creator_id: 1,
      start_ts: 1.hour.from_now.to_i,
      message: nil,
      joiner_ids: [],
      notify_reply_id:,
      started: false
    )
    JSON.parse(rendered.to_json).to_json
  end

  before do
    allow(Bot::Config).to receive(:token).and_return("tok")
    allow(Discordrb::API::Channel).to receive(:message).and_return(message_json(notify_reply_id:))
    allow(Discordrb::API::Channel).to receive(:delete_message)
  end

  context "when the requester is the creator" do
    let(:uid) { 1 }

    it "defers ephemerally" do
      expect(event).to receive(:defer).with(ephemeral: true)
      handle
    end

    it "deletes the notify reply and the post" do
      handle
      expect(Discordrb::API::Channel).to have_received(:delete_message).with("Bot tok", 20, 600)
      expect(Discordrb::API::Channel).to have_received(:delete_message).with("Bot tok", 20, 500)
    end

    it "edits the response to confirm closure" do
      expect(event).to receive(:edit_response).with(content: "LFG closed.")
      handle
    end
  end

  context "when the requester is not the creator and cannot manage messages" do
    let(:uid) { 2 }

    it "responds as unauthorized" do
      expect(event).to receive(:respond).with(content: "Only the poster or a mod can close this LFG.", ephemeral: true)
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

    it "is authorized to close" do
      expect(event).to receive(:defer).with(ephemeral: true)
      handle
    end

    it "deletes the notify reply and the post" do
      handle
      expect(Discordrb::API::Channel).to have_received(:delete_message).with("Bot tok", 20, 600)
      expect(Discordrb::API::Channel).to have_received(:delete_message).with("Bot tok", 20, 500)
    end
  end
end
