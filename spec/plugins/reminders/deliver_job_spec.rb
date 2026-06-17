require "rails_helper"
require "discordrb" # the job sends over REST; load the client so we can stub it

RSpec.describe Reminders::DeliverJob do
  subject(:perform) { described_class.perform_now(reminder_id) }

  # REST calls must use the "Bot <token>" form (BotConfig.rest_token).
  let(:reminder) do
    create(:reminder, user_id: 10, channel_id: 20, server_id: 30, remind_at: 1.minute.ago, message: "hello")
  end
  let(:reminder_id) { reminder.id }

  before { allow(BotConfig).to receive(:token).and_return("tok") }

  context "in a channel" do
    it "posts the reminder to its channel and then deletes it" do
      expect(Discordrb::API::Channel).to receive(:create_message).with("Bot tok", 20, a_string_including("hello"))
      perform
      expect(Reminders::Reminder.exists?(reminder.id)).to be(false)
    end
  end

  context "when the reminder is already gone" do
    let(:reminder_id) { "rmd_missing" }

    it "no-ops (idempotent)" do
      expect(Discordrb::API::Channel).not_to receive(:create_message)
      expect { perform }.not_to raise_error
    end
  end

  context "when the user requested DM delivery" do
    before do
      reminder.update!(deliver_via_dm: true)
      allow(Discordrb::API::User).to receive(:create_pm).with("Bot tok", 10).and_return({id: 77}.to_json)
    end

    it "delivers via DM" do
      expect(Discordrb::API::Channel).to receive(:create_message).with("Bot tok", 77, anything)
      perform
    end
  end

  context "when the server forces DM delivery" do
    before do
      create(:server_configuration, discord_id: 30, force_dm_reminders: true)
      allow(Discordrb::API::User).to receive(:create_pm).with("Bot tok", 10).and_return({id: 88}.to_json)
    end

    it "delivers via DM" do
      expect(Discordrb::API::Channel).to receive(:create_message).with("Bot tok", 88, anything)
      perform
    end
  end
end
