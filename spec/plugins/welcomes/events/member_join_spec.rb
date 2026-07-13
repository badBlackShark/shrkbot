# frozen_string_literal: true

require "rails_helper"

RSpec.describe Welcomes::MemberJoin do
  subject(:handle) { described_class.new(event).handle }

  let(:server) { double("server", id: 123, member_count: 10) }
  let(:user) { double("user", mention: "<@7>") }
  let(:bot) { double("bot") }
  let(:event) { double("event", server:, user:, bot:) }

  before do
    allow(Welcomes::Settings).to receive(:active_for).with(123).and_return(setting)
  end

  context "with an active setting and a join message" do
    let(:setting) { double("settings", channel_id: 555, join_message: "Welcome {user}! Members: {membercount}", ping_on_join: true) }

    it "posts the rendered message to the configured channel" do
      expect(bot).to receive(:send_message).with(555, "Welcome <@7>! Members: 10", false, nil, nil, nil)
      handle
    end
  end

  context "when pinging on join is disabled" do
    let(:setting) { double("settings", channel_id: 555, join_message: "Welcome {user}!", ping_on_join: false) }

    it "suppresses the mention so no ping fires" do
      expect(bot).to receive(:send_message).with(555, "Welcome <@7>!", false, nil, nil, {parse: []})
      handle
    end
  end

  context "when welcomes is inactive" do
    let(:setting) { nil }

    it "does nothing" do
      expect(bot).not_to receive(:send_message)
      handle
    end
  end

  context "when the join message is blank" do
    let(:setting) { double("settings", channel_id: 555, join_message: "") }

    it "does nothing" do
      expect(bot).not_to receive(:send_message)
      handle
    end
  end

  context "when no channel is set" do
    let(:setting) { double("settings", channel_id: nil, join_message: "hi") }

    it "does nothing" do
      expect(bot).not_to receive(:send_message)
      handle
    end
  end
end
