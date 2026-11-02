# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe Integrations::Twitch::ReportEventSubJob do
  subject(:perform) { described_class.perform_now(lines) }

  let(:rest_token) { "Bot test-token" }
  let(:lines) { ["Twitch revoked 3 subscriptions: notification_failures_exceeded."] }

  before do
    allow(Bot::Config).to receive_messages(owner_id: "999", rest_token:)
    allow(Discordrb::API::User).to receive(:create_pm).with(rest_token, "999").and_return({id: 77}.to_json)
    allow(Bot::Discord::Components).to receive(:create_message)
  end

  it "DMs the owner the problems" do
    perform

    expect(Bot::Discord::Components).to have_received(:create_message).with(
      channel_id: 77,
      content: "Twitch EventSub needs a look:\n- Twitch revoked 3 subscriptions: notification_failures_exceeded.",
      allowed_mentions: {parse: []}
    )
  end
end
