# frozen_string_literal: true

require "rails_helper"

RSpec.describe Welcomes::OnboardingComplete do
  subject(:handle) { described_class.new(event).handle }

  let(:server) { double("server", id: 123, member_count: 10) }
  let(:user) { double("user", mention: "<@7>", id: 7, pending: false) }
  let(:bot) { double("bot", send_message: nil) }
  let(:event) { double("event", server:, user:, bot:) }
  let(:pending_joins) { Welcomes::PendingJoins.new }
  let(:setting) { double("settings", channel_id: 555, join_message: "Welcome {user}! Members: {membercount}", ping_on_join: true) }

  before do
    allow(Welcomes::PendingJoins).to receive(:instance).and_return(pending_joins)
    allow(Welcomes::Settings).to receive(:active_for).with(123).and_return(setting)
  end

  context "when the member finished onboarding after a held-back join" do
    before { pending_joins.remember(guild_id: 123, user_id: 7) }

    it "posts the welcome it held back" do
      handle

      expect(bot).to have_received(:send_message).with(555, "Welcome <@7>! Members: 10", false, nil, nil, nil)
    end

    it "posts it only once, however many updates follow" do
      handle
      described_class.new(event).handle

      expect(bot).to have_received(:send_message).once
    end
  end

  context "when the update is an ordinary nickname or role change" do
    it "does nothing" do
      handle

      expect(bot).not_to have_received(:send_message)
    end
  end

  context "when the member has onboarding left to finish" do
    let(:user) { double("user", mention: "<@7>", id: 7, pending: true) }

    before { pending_joins.remember(guild_id: 123, user_id: 7) }

    it "keeps holding the welcome back" do
      handle

      expect(bot).not_to have_received(:send_message)
    end

    it "leaves the held-back join in place" do
      handle

      expect(pending_joins.forget(guild_id: 123, user_id: 7)).to be(true)
    end
  end

  context "when the server is not cached" do
    let(:user) { nil }

    it "does nothing" do
      handle

      expect(bot).not_to have_received(:send_message)
    end
  end
end
