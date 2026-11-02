# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe Integrations::Twitch::ReportUnauthorizedJob do
  subject(:perform) { described_class.perform_now("id.twitch.tv responded 400") }

  let(:rest_token) { "Bot test-token" }

  before do
    allow(Bot::Config).to receive_messages(owner_id: "999", rest_token:)
    allow(Discordrb::API::User).to receive(:create_pm).with(rest_token, "999").and_return({id: 77}.to_json)
    allow(Bot::Discord::Components).to receive(:create_message)
  end

  it "DMs the owner which credentials to check" do
    perform

    expect(Bot::Discord::Components).to have_received(:create_message).with(
      channel_id: 77,
      content: "Twitch rejected shrkbot's app credentials: id.twitch.tv responded 400. Live tracking and EventSub stay off " \
        "until TWITCH_CLIENT_ID and TWITCH_CLIENT_SECRET work again.",
      allowed_mentions: {parse: []}
    )
  end
end
