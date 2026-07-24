# frozen_string_literal: true

require "rails_helper"

RSpec.describe Welcomes::JoinAnnouncement do
  subject(:deliver) { described_class.new(bot:, server:, member:).deliver }

  let(:server) { double("server", id: 123, member_count: 10) }
  let(:member) { double("member", id: 7, mention: "<@7>", username: "newmember", display_name: "New Member") }
  let(:bot) { double("bot") }

  before do
    allow(Welcomes::Settings).to receive(:active_for).with(123).and_return(setting)
  end

  context "with an active setting and a join message" do
    let(:setting) { double("settings", channel_id: 555, join_message: "Welcome {user}! Members: {membercount}", ping_on_join: true) }

    it "posts the rendered message to the configured channel" do
      expect(bot).to receive(:send_message).with(555, "Welcome <@7>! Members: 10", false, nil, nil, nil, nil, nil, 0)
      deliver
    end
  end

  context "with the name placeholders in the join message" do
    let(:setting) { double("settings", channel_id: 555, join_message: "{username} aka {displayname}", ping_on_join: true) }

    it "renders the username and display name" do
      expect(bot).to receive(:send_message).with(555, "newmember aka New Member", false, nil, nil, nil, nil, nil, 0)
      deliver
    end
  end

  context "when pinging on join is disabled" do
    let(:setting) { double("settings", channel_id: 555, join_message: "Welcome {user}!", ping_on_join: false) }

    it "keeps the mention resolvable but sends the message silently" do
      expect(bot).to receive(:send_message).with(
        555,
        "Welcome <@7>!",
        false,
        nil,
        nil,
        {parse: [], users: [7]},
        nil,
        nil,
        described_class::SUPPRESS_NOTIFICATIONS
      )
      deliver
    end
  end

  context "when welcomes is inactive" do
    let(:setting) { nil }

    it "does nothing" do
      expect(bot).not_to receive(:send_message)
      deliver
    end
  end

  context "when the join message is blank" do
    let(:setting) { double("settings", channel_id: 555, join_message: "") }

    it "does nothing" do
      expect(bot).not_to receive(:send_message)
      deliver
    end
  end

  context "when no channel is set" do
    let(:setting) { double("settings", channel_id: nil, join_message: "hi") }

    it "does nothing" do
      expect(bot).not_to receive(:send_message)
      deliver
    end
  end
end
