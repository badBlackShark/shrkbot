# frozen_string_literal: true

require "rails_helper"

RSpec.describe Commands::Ping do
  it "replies with an ephemeral pong" do
    event = double("event", respond: nil)
    expect(event).to receive(:respond).with(hash_including(content: a_string_including("pong"), ephemeral: true))
    described_class.new(event).execute
  end
end
