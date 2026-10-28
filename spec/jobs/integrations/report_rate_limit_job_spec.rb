# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe Integrations::ReportRateLimitJob do
  subject(:perform) { described_class.perform_now("Team Fortress 2 (440)", "api.steampowered.com responded 429", retry_after) }

  let(:rest_token) { "Bot test-token" }
  let(:retry_after) { nil }

  before do
    allow(Bot::Config).to receive_messages(owner_id: "999", rest_token:)
    allow(Discordrb::API::User).to receive(:create_pm).with(rest_token, "999").and_return({id: 77}.to_json)
    allow(Bot::Discord::Components).to receive(:create_message)
  end

  it "DMs the owner the rate-limited watch" do
    perform

    expect(Bot::Discord::Components).to have_received(:create_message).with(
      channel_id: 77,
      content: "Polling was rate-limited at Team Fortress 2 (440): api.steampowered.com responded 429. The batch stopped until the next tick.",
      allowed_mentions: {parse: []}
    )
  end

  context "when the provider sent Retry-After" do
    let(:retry_after) { 120 }

    it "names the wait" do
      perform

      expect(Bot::Discord::Components).to have_received(:create_message).with(
        hash_including(content: a_string_ending_with("until the next tick. Retry-After: 120 s."))
      )
    end
  end
end
