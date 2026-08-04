# frozen_string_literal: true

require "rails_helper"

RSpec.describe Welcomes::MemberLeave do
  subject(:handle) { described_class.new(event).handle }

  let(:server) { double("server", id: 123, member_count: 9) }
  let(:user) { double("user", username: "ghost", display_name: "Ghost", id: 7) }
  let(:bot) { double("bot") }
  let(:event) { double("event", server:, user:, bot:) }
  let(:pending_joins) { Welcomes::PendingJoins.new }

  before do
    allow(Welcomes::PendingJoins).to receive(:instance).and_return(pending_joins)
    allow(Welcomes::Settings).to receive(:active_for).with(123).and_return(setting)
  end

  context "with an active setting and a leave message" do
    let(:setting) { double("settings", channel_id: 555, leave_message: "{user} left. {membercount} remain.", suppress_removal_messages: false) }

    it "posts the rendered message with the @handle and suppresses all mentions" do
      expect(bot).to receive(:send_message).with(555, "@ghost left. 9 remain.", false, nil, nil, {parse: []})
      handle
    end
  end

  context "with the name placeholders in the leave message" do
    let(:setting) { double("settings", channel_id: 555, leave_message: "{displayname} ({username}) left.", suppress_removal_messages: false) }

    it "renders the display name and username" do
      expect(bot).to receive(:send_message).with(555, "Ghost (ghost) left.", false, nil, nil, {parse: []})
      handle
    end
  end

  context "when the leave message is blank" do
    let(:setting) { double("settings", channel_id: 555, leave_message: "", suppress_removal_messages: false) }

    it "does nothing" do
      expect(bot).not_to receive(:send_message)
      handle
    end
  end

  context "when suppress_removal_messages is enabled" do
    let(:setting) { double("settings", channel_id: 555, leave_message: "{user} left. {membercount} remain.", suppress_removal_messages: true) }
    let(:pending_removals) { Welcomes::PendingRemovals.new }

    before do
      allow(Welcomes::PendingRemovals).to receive(:instance).and_return(pending_removals)
      allow(Welcomes::GracePeriod).to receive(:after) { |&block| block.call }
    end

    context "when the removal was a kick or ban" do
      before { pending_removals.remember(guild_id: 123, user_id: 7) }

      it "sends no leave message" do
        expect(bot).not_to receive(:send_message)
        handle
      end
    end

    context "when the member left voluntarily" do
      it "still posts the leave message" do
        expect(bot).to receive(:send_message).with(555, "@ghost left. 9 remain.", false, nil, nil, {parse: []})
        handle
      end
    end
  end

  context "when suppress_removal_messages is disabled" do
    let(:setting) { double("settings", channel_id: 555, leave_message: "{user} left. {membercount} remain.", suppress_removal_messages: false) }

    it "posts immediately without going through the grace period" do
      expect(Welcomes::GracePeriod).not_to receive(:after)
      expect(bot).to receive(:send_message).with(555, "@ghost left. 9 remain.", false, nil, nil, {parse: []})
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

  context "when the member leaves before finishing onboarding" do
    let(:setting) { nil }

    before { pending_joins.remember(guild_id: 123, user_id: 7) }

    it "drops the held-back join instead of waiting out its retention" do
      handle

      expect(pending_joins.forget(guild_id: 123, user_id: 7)).to be(false)
    end
  end
end
