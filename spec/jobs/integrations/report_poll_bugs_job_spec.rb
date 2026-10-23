# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe Integrations::ReportPollBugsJob do
  subject(:perform) { described_class.perform_now(lines) }

  let(:rest_token) { "Bot test-token" }
  let(:lines) { ["Team Fortress 2 (440): NoMethodError: our bug"] }

  before do
    allow(Bot::Config).to receive_messages(owner_id: "999", rest_token:)
    allow(Discordrb::API::User).to receive(:create_pm).with(rest_token, "999").and_return({id: 77}.to_json)
    allow(Bot::Discord::Components).to receive(:create_message)
  end

  it "DMs the owner the bugs" do
    perform

    expect(Bot::Discord::Components).to have_received(:create_message).with(
      channel_id: 77,
      content: "Polling hit a bug in shrkbot:\n- Team Fortress 2 (440): NoMethodError: our bug",
      allowed_mentions: {parse: []}
    )
  end

  context "with more than 10 lines" do
    let(:lines) { Array.new(12) { |index| "Game #{index}: boom" } }

    it "lists ten and summarises the rest" do
      perform

      expect(Bot::Discord::Components).to have_received(:create_message).with(
        hash_including(content: a_string_matching(/\A(?:[^\n]*\n){10}- Game 9: boom\n- and 2 more\z/))
      )
    end
  end
end
