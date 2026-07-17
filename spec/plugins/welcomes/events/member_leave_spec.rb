# frozen_string_literal: true

require "rails_helper"

RSpec.describe Welcomes::MemberLeave do
  subject(:handle) { described_class.new(event).handle }

  let(:server) { double("server", id: 123, member_count: 9) }
  let(:user) { double("user", username: "ghost") }
  let(:bot) { double("bot") }
  let(:event) { double("event", server:, user:, bot:) }

  before do
    allow(Welcomes::Settings).to receive(:active_for).with(123).and_return(setting)
  end

  context "with an active setting and a leave message" do
    let(:setting) { double("settings", channel_id: 555, leave_message: "{user} left. {membercount} remain.") }

    it "posts the rendered message with the @handle and suppresses all mentions" do
      expect(bot).to receive(:send_message).with(555, "@ghost left. 9 remain.", false, nil, nil, {parse: []})
      handle
    end
  end

  context "when the leave message is blank" do
    let(:setting) { double("settings", channel_id: 555, leave_message: "") }

    it "does nothing" do
      expect(bot).not_to receive(:send_message)
      handle
    end
  end

  context "when the plugin isn't configured for the server" do
    let(:setting) { nil }

    it "does nothing" do
      expect(bot).not_to receive(:send_message)
      handle
    end
  end
end
