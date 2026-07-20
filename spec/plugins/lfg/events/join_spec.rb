# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe Lfg::Join do
  subject(:handle) { described_class.new(event).handle }

  let(:creator_id) { 99 }
  let(:role_id) { 55 }
  let(:start_ts) { 1.hour.from_now.to_i }
  let(:joiner_ids) { [] }
  let(:note) { nil }

  let(:custom_id) { Lfg::CustomId.join(creator_id, start_ts, role_id) }
  let(:channel) { double("channel", id: 20) }
  let(:message) { double("message", id: 500) }
  let(:user) { double("user", id: 42) }
  let(:event) do
    double("event", defer_update: nil, channel:, message:, user:, custom_id:, send_message: nil)
  end

  let!(:lfg_message) { create(:lfg_message, message_id: 500) }

  def message_json(start_ts:, joiner_ids:, note: nil)
    rendered = Lfg::PostMessage.render(
      role_id:,
      creator_id:,
      start_ts:,
      message: note,
      joiner_ids:,
      started: Time.current.to_i >= start_ts
    )
    JSON.parse(rendered.to_json).to_json
  end

  def joiner_ids_from(container)
    Lfg::PostMessage.parse(JSON.parse(container.to_json))[:joiner_ids]
  end

  before do
    allow(Bot::Config).to receive(:token).and_return("tok")
    allow(Discordrb::API::Channel).to receive(:message)
      .and_return(message_json(start_ts:, joiner_ids:, note:))
    allow(Bot::Discord::Components).to receive(:convert_to_v2)
    allow(Lfg::PingReply).to receive(:deliver).and_return(700)
    allow(Discordrb::API::Channel).to receive(:delete_message)
  end

  it "always defers the interaction update" do
    expect(event).to receive(:defer_update)
    handle
  end

  context "gathering (start_ts in the future), not yet joined" do
    it "adds the user and re-renders with the joiner in the last block" do
      handle
      expect(Bot::Discord::Components).to have_received(:convert_to_v2) do |_channel_id, _message_id, container|
        expect(joiner_ids_from(container)).to include(42)
      end
    end

    it "does not send a ping reply while still gathering" do
      expect(Lfg::PingReply).not_to receive(:deliver)
      handle
    end

    context "with a note on the post" do
      let(:note) { "bring snacks" }

      it "carries the note through the re-render" do
        handle
        expect(Bot::Discord::Components).to have_received(:convert_to_v2) do |_channel_id, _message_id, container|
          expect(JSON.parse(container.to_json).to_json).to include("bring snacks")
        end
      end
    end
  end

  context "already joined" do
    let(:joiner_ids) { [42, 7] }

    it "removes the user and re-renders" do
      handle
      expect(Bot::Discord::Components).to have_received(:convert_to_v2) do |_channel_id, _message_id, container|
        expect(joiner_ids_from(container)).not_to include(42)
        expect(joiner_ids_from(container)).to include(7)
      end
    end

    it "does not send a ping reply while leaving" do
      expect(Lfg::PingReply).not_to receive(:deliver)
      handle
    end
  end

  context "started (start_ts in the past), joining" do
    let(:start_ts) { 1.hour.ago.to_i }

    it "delivers a ping reply naming the creator only" do
      expect(Lfg::PingReply).to receive(:deliver).with(
        hash_including(
          channel_id: 20,
          reply_to_id: 500,
          allowed_mentions: {parse: [], users: [creator_id]}
        )
      ).and_return(700)
      handle
    end

    it "names all joiners and calls out the newest in the notify container" do
      handle
      expect(Lfg::PingReply).to have_received(:deliver) do |**kwargs|
        content = kwargs[:container][:components].first[:components].first[:content]
        expect(content).to include("<@42> just joined")
        expect(content).to include("(1)")
      end
    end

    it "records the returned reply id on the message row" do
      allow(Lfg::PingReply).to receive(:deliver).and_return(701)
      expect(Ops::Lfg::Message::Update).to receive(:call).with(message: lfg_message, notify_reply_id: 701)
      handle
    end

    it "still re-renders the post" do
      handle
      expect(Bot::Discord::Components).to have_received(:convert_to_v2)
    end

    context "when the post has no message row" do
      before { lfg_message.destroy }

      it "still delivers the notify but records nothing" do
        expect(Lfg::PingReply).to receive(:deliver).and_return(701)
        expect(Ops::Lfg::Message::Update).not_to receive(:call)
        handle
      end
    end

    context "when a prior notify reply exists" do
      let!(:lfg_message) { create(:lfg_message, message_id: 500, notify_reply_id: 600) }

      it "deletes the previous notify reply before posting a new one" do
        handle
        expect(Discordrb::API::Channel).to have_received(:delete_message).with("Bot tok", 20, 600)
        expect(Lfg::PingReply).to have_received(:deliver)
      end
    end
  end

  context "when the Looking for Game is at capacity" do
    let(:joiner_ids) { (100..199).to_a }

    it "responds ephemerally instead of joining" do
      expect(event).to receive(:send_message).with(hash_including(ephemeral: true))
      handle
    end

    it "does not re-render" do
      handle
      expect(Bot::Discord::Components).not_to have_received(:convert_to_v2)
    end
  end

  context "when the message is gone (404)" do
    before do
      allow(Discordrb::API::Channel).to receive(:message)
        .and_raise(Discordrb::Errors::UnknownMessage.new("Unknown Message"))
    end

    it "no-ops" do
      handle
      expect(Bot::Discord::Components).not_to have_received(:convert_to_v2)
    end
  end
end
