# frozen_string_literal: true

require "rails_helper"
require "discordrb" # the job sends over REST; load the client so we can stub it

RSpec.describe Reminders::DeliverJob do
  subject(:perform) { described_class.perform_now(reminder_id) }

  let(:reminder) do
    create(:reminder, user_id: 10, channel_id: 20, server_id: 30, remind_at: 1.minute.ago, message: "hello")
  end
  let(:reminder_id) { reminder.id }

  before do
    allow(BotConfig).to receive(:token).and_return("tok")
  end

  context "in a channel" do
    it "posts the reminder as a branded container and then deletes it" do
      expect(Discordrb::API::Channel).to receive(:create_message) do |token, channel_id, content, _tts, _embeds, _nonce, _attachments, _allowed_mentions, _message_reference, components, flags|
        expect(token).to eq("Bot tok")
        expect(channel_id).to eq(20)
        expect(content).to be_nil
        expect(flags).to eq(Discord::Components::COMPONENTS_V2)
        body = components.first[:components].first[:content]
        expect(body).to include("<@10>")
        expect(body).to include("hello")
      end
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

  context "when the reminder has no server (DM-origin) and no DM flag" do
    let(:reminder) do
      create(:reminder, user_id: 10, channel_id: 20, server_id: nil, remind_at: 1.minute.ago, message: "hello")
    end

    it "delivers to the original channel" do
      expect(Discordrb::API::Channel).to receive(:create_message).with("Bot tok", 20, any_args)
      perform
    end
  end

  context "when the user requested DM delivery" do
    before do
      reminder.update!(deliver_via_dm: true)
      allow(Discordrb::API::User).to receive(:create_pm).with("Bot tok", 10).and_return({id: 77}.to_json)
    end

    it "delivers via DM" do
      expect(Discordrb::API::Channel).to receive(:create_message).with("Bot tok", 77, any_args)
      perform
    end
  end

  context "when the server forces DM delivery" do
    before do
      create(:server_configuration, discord_id: 30, force_dm_reminders: true)
      allow(Discordrb::API::User).to receive(:create_pm).with("Bot tok", 10).and_return({id: 88}.to_json)
    end

    it "delivers via DM" do
      expect(Discordrb::API::Channel).to receive(:create_message).with("Bot tok", 88, any_args)
      perform
    end
  end
end
