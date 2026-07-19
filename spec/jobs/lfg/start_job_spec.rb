# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe Lfg::StartJob do
  subject(:perform) { described_class.perform_now(20, 500) }

  let(:joiner_ids) { [1, 2] }

  def message_json(joiner_ids:)
    rendered = Lfg::PostMessage.render(
      role_id: 55,
      creator_id: 99,
      start_ts: 1.hour.ago.to_i,
      message: nil,
      joiner_ids:,
      notify_reply_id: nil,
      started: true
    )
    JSON.parse(rendered.to_json).to_json
  end

  before do
    allow(Bot::Config).to receive(:token).and_return("tok")
    allow(Discordrb::API::Channel).to receive(:message).and_return(message_json(joiner_ids:))
    allow(Lfg::PingReply).to receive(:deliver).and_return(700)
  end

  it "re-pings the joiners, mentioning them only" do
    expect(Lfg::PingReply).to receive(:deliver).with(
      hash_including(channel_id: 20, reply_to_id: 500, allowed_mentions: {parse: [], users: [1, 2]})
    ).and_return(700)
    perform
  end

  context "when nobody joined" do
    let(:joiner_ids) { [] }

    it "does not deliver a ping reply" do
      expect(Lfg::PingReply).not_to receive(:deliver)
      perform
    end
  end

  context "when the message is gone (404)" do
    before do
      allow(Discordrb::API::Channel).to receive(:message).and_raise(Discordrb::Errors::UnknownMessage.new("Unknown Message"))
    end

    it "no-ops without raising" do
      expect(Lfg::PingReply).not_to receive(:deliver)
      expect { perform }.not_to raise_error
    end
  end
end
