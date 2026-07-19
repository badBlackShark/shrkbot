# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe Lfg::PingReply do
  subject(:deliver) do
    described_class.deliver(
      channel_id:,
      reply_to_id:,
      subject: subject_text,
      allowed_mentions:,
      container:
    )
  end

  let(:channel_id) { 20 }
  let(:reply_to_id) { 500 }
  let(:subject_text) { "hello there" }
  let(:allowed_mentions) { {parse: [], users: [1]} }
  let(:container) { Bot::Discord::Components.container([Bot::Discord::Components.text("hi")]) }

  before do
    allow(Bot::Config).to receive(:token).and_return("tok")
    allow(Discordrb::API::Channel).to receive(:create_message).and_return({id: 99}.to_json)
    allow(Bot::Discord::Components).to receive(:convert_to_v2)
  end

  it "creates the reply message with the subject content, allowed_mentions, and reply reference" do
    expect(Discordrb::API::Channel).to receive(:create_message) do |token, chan_id, content, _tts, _embeds, _nonce, _attachments, mentions, message_reference, _components, _flags|
      expect(token).to eq("Bot tok")
      expect(chan_id).to eq(20)
      expect(content).to eq(subject_text)
      expect(mentions).to eq(allowed_mentions)
      expect(message_reference).to eq({message_id: 500})
      {id: 99}.to_json
    end
    deliver
  end

  it "converts the created message to the branded container" do
    expect(Bot::Discord::Components).to receive(:convert_to_v2).with(20, 99, container)
    deliver
  end

  it "returns the new message id" do
    expect(deliver).to eq(99)
  end
end
