require "rails_helper"
require "discordrb" # the job sends over REST; load the client so we can stub it

RSpec.describe Reminders::DeliverJob do
  before { allow(BotConfig).to receive(:token).and_return("tok") }

  let(:reminder) do
    Reminders::Reminder.create!(user_id: 10, channel_id: 20, server_id: 30, remind_at: 1.minute.ago, message: "hello")
  end

  it "posts the reminder to its channel and then deletes it" do
    expect(Discordrb::API::Channel).to receive(:create_message).with("tok", 20, a_string_including("hello"))
    described_class.perform_now(reminder.id)
    expect(Reminders::Reminder.exists?(reminder.id)).to be(false)
  end

  it "no-ops when the reminder is already gone (idempotent)" do
    expect(Discordrb::API::Channel).not_to receive(:create_message)
    expect { described_class.perform_now("rmd_missing") }.not_to raise_error
  end

  it "delivers via DM when the user requested it" do
    reminder.update!(deliver_via_dm: true)
    allow(Discordrb::API::User).to receive(:create_pm).with("tok", 10).and_return({id: 77}.to_json)
    expect(Discordrb::API::Channel).to receive(:create_message).with("tok", 77, anything)
    described_class.perform_now(reminder.id)
  end

  it "delivers via DM when the server forces it" do
    ServerConfiguration.create!(discord_id: 30, force_dm_reminders: true)
    allow(Discordrb::API::User).to receive(:create_pm).with("tok", 10).and_return({id: 88}.to_json)
    expect(Discordrb::API::Channel).to receive(:create_message).with("tok", 88, anything)
    described_class.perform_now(reminder.id)
  end
end
