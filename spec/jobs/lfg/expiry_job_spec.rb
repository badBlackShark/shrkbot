# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe Lfg::ExpiryJob do
  subject(:perform) { described_class.perform_now(20, 500) }

  def message_json(notify_reply_id:)
    rendered = Lfg::PostMessage.render(
      role_id: 55,
      creator_id: 99,
      start_ts: 1.hour.ago.to_i,
      message: nil,
      joiner_ids: [],
      notify_reply_id:,
      started: true
    )
    JSON.parse(rendered.to_json).to_json
  end

  before do
    allow(Bot::Config).to receive(:token).and_return("tok")
    allow(Discordrb::API::Channel).to receive(:delete_message)
  end

  context "when the post has a notify reply" do
    before do
      allow(Discordrb::API::Channel).to receive(:message).and_return(message_json(notify_reply_id: 700))
    end

    it "deletes both the notify reply and the post" do
      perform
      expect(Discordrb::API::Channel).to have_received(:delete_message).with("Bot tok", 20, 700)
      expect(Discordrb::API::Channel).to have_received(:delete_message).with("Bot tok", 20, 500)
    end
  end

  context "when the post has no notify reply" do
    before do
      allow(Discordrb::API::Channel).to receive(:message).and_return(message_json(notify_reply_id: nil))
    end

    it "deletes only the post" do
      perform
      expect(Discordrb::API::Channel).to have_received(:delete_message).with("Bot tok", 20, 500).once
    end
  end

  context "when the fetched message is not an LFG post" do
    before do
      allow(Discordrb::API::Channel).to receive(:message)
        .and_return({"components" => [{"type" => 10, "content" => "hi"}]}.to_json)
    end

    it "deletes only the post" do
      perform
      expect(Discordrb::API::Channel).to have_received(:delete_message).with("Bot tok", 20, 500).once
    end
  end

  context "when the message fetch 404s" do
    before do
      allow(Discordrb::API::Channel).to receive(:message).and_raise(Discordrb::Errors::UnknownMessage.new("Unknown Message"))
    end

    it "still attempts to delete the post without raising" do
      expect { perform }.not_to raise_error
      expect(Discordrb::API::Channel).to have_received(:delete_message).with("Bot tok", 20, 500)
    end
  end

  context "when deleting the post 404s" do
    before do
      allow(Discordrb::API::Channel).to receive(:message).and_return(message_json(notify_reply_id: nil))
      allow(Discordrb::API::Channel).to receive(:delete_message).and_raise(Discordrb::Errors::UnknownMessage.new("Unknown Message"))
    end

    it "does not raise" do
      expect { perform }.not_to raise_error
    end
  end
end
