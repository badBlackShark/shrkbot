# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe Integrations::Twitch::ReportLiveCheckBrokenJob do
  subject(:perform) { described_class.perform_now("Integrations::Unavailable: api.twitch.tv responded 503") }

  let(:rest_token) { "Bot test-token" }

  before do
    allow(Bot::Config).to receive_messages(owner_id: "999", rest_token:)
    allow(Discordrb::API::User).to receive(:create_pm).with(rest_token, "999").and_return({id: 77}.to_json)
    allow(Bot::Discord::Components).to receive(:create_message)
  end

  it "DMs the owner what stops while the check fails" do
    perform

    expect(Bot::Discord::Components).to have_received(:create_message).with(
      channel_id: 77,
      content: "Twitch live checks have failed for 24 hours: Integrations::Unavailable: api.twitch.tv responded 503. " \
        "Live cards stop updating, and streams that end meanwhile are marked ended once the checks recover. shrkbot retries every 10 minutes.",
      allowed_mentions: {parse: []}
    )
  end
end
