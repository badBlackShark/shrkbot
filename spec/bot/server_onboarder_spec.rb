# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServerOnboarder do
  subject(:notify) { described_class.notify(bot, server, config) }

  let(:config) { create(:server_configuration) }
  let(:owner) { double("owner", id: 999) }
  let(:server) { double("server", id: 77, owner:) }
  let(:pm_channel) { double("pm_channel", send_message: nil) }
  let(:bot) { double("bot", pm_channel: pm_channel) }

  context "when the server has not been onboarded" do
    it "DMs the guild owner the welcome message" do
      expect(bot).to receive(:pm_channel).with(999).and_return(pm_channel)
      expect(pm_channel).to receive(:send_message).with(described_class::WELCOME_MESSAGE)
      notify
    end

    it "records when the server was onboarded" do
      expect { notify }.to change { config.reload.onboarded_at }.from(nil)
    end
  end

  context "when the server has already been onboarded" do
    before do
      config.update!(onboarded_at: 1.day.ago)
    end

    it "does not DM the owner again" do
      expect(bot).not_to receive(:pm_channel)
      notify
    end

    it "leaves the timestamp untouched" do
      expect { notify }.not_to change { config.reload.onboarded_at }
    end
  end

  context "when the owner cannot be DMed" do
    before do
      allow(bot).to receive(:pm_channel).and_raise(StandardError, "Cannot send messages to this user")
    end

    it "swallows the error and leaves the server un-onboarded" do
      expect { notify }.not_to change { config.reload.onboarded_at }
    end
  end
end
