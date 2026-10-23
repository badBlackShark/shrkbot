# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe ReportExhaustedJob do
  subject(:perform) { described_class.perform_now(line) }

  let(:rest_token) { "Bot test-token" }
  let(:line) { "Feeds::PostJob job-1: RuntimeError: discord is down" }

  before do
    allow(Bot::Config).to receive_messages(owner_id: "999", rest_token:)
    allow(Discordrb::API::User).to receive(:create_pm).with(rest_token, "999").and_return({id: 77}.to_json)
    allow(Bot::Discord::Components).to receive(:create_message)
  end

  it "DMs the owner which job gave up and why" do
    perform

    expect(Bot::Discord::Components).to have_received(:create_message).with(
      channel_id: 77,
      content: "A job gave up after 5 attempts:\n- Feeds::PostJob job-1: RuntimeError: discord is down",
      allowed_mentions: {parse: []}
    )
  end
end
