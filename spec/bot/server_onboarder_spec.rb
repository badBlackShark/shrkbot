# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::ServerOnboarder do
  subject(:notify) { described_class.notify(bot, server, config) }

  let(:config) { create(:server_configuration) }
  let(:owner) { double("owner", id: 999) }
  let(:server) { double("server", id: 77, name: "Dev Refuge", owner:) }
  let(:pm_channel) { double("pm_channel") }
  let(:bot) { double("bot", pm_channel:) }

  before do
    allow(Bot::Discord::Components).to receive(:send_to)
  end

  context "when the server has not been onboarded" do
    before do
      allow(Bot::Config).to receive(:web_base_url).and_return("https://shrkbot.gg")
    end

    it "DMs the guild owner" do
      expect(bot).to receive(:pm_channel).with(999).and_return(pm_channel)
      notify
    end

    it "sends a branded container with the deep dashboard link and server name" do
      expect(Bot::Discord::Components).to receive(:send_to) do |_channel, rendered, **options|
        expect(rendered[:flags]).to eq(Bot::Discord::Components::COMPONENTS_V2)
        expect(rendered[:components].to_s).to include("https://shrkbot.gg/servers/77")
        expect(rendered[:components].to_s).to include("Dev Refuge")
      end
      notify
    end

    it "passes a plain summary as the push-notification subject" do
      expect(Bot::Discord::Components).to receive(:send_to).with(
        pm_channel,
        anything,
        subject: "Thanks for adding shrkbot! Set up Dev Refuge on the web dashboard."
      )
      notify
    end

    it "records when the server was onboarded" do
      expect { notify }.to change { config.reload.onboarded_at }.from(nil)
    end
  end

  context "when the server has already been onboarded" do
    before do
      allow(Bot::Config).to receive(:web_base_url).and_return("https://shrkbot.gg")
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
      allow(Bot::Config).to receive(:web_base_url).and_return("https://shrkbot.gg")
      allow(bot).to receive(:pm_channel).and_raise(StandardError, "Cannot send messages to this user")
    end

    it "swallows the error and leaves the server un-onboarded" do
      expect { notify }.not_to change { config.reload.onboarded_at }
    end
  end
end
