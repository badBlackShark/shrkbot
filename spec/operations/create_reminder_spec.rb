require "rails_helper"

RSpec.describe CreateReminder do
  it "creates a reminder and schedules delivery for the parsed time" do
    result = nil
    expect {
      result = described_class.call(user_id: 1, channel_id: 2, server_id: 3, message: "ping me", duration: "1h")
    }.to have_enqueued_job(Reminders::DeliverJob).with(kind_of(String)).at(a_value_within(1.minute).of(1.hour.from_now))

    expect(result.success?).to be(true)
    expect(result.value.remind_at).to be_within(1.minute).of(1.hour.from_now)
    expect(result.value.message).to eq("ping me")
  end

  it "sanitizes the message before persisting" do
    result = described_class.call(user_id: 1, channel_id: 2, message: "@everyone hi", duration: "1h")
    expect(result.value.message).not_to include("@everyone")
  end

  it "fails on an unparseable duration without creating or scheduling" do
    result = nil
    expect {
      expect {
        result = described_class.call(user_id: 1, channel_id: 2, message: "x", duration: "soon")
      }.not_to change(Reminders::Reminder, :count)
    }.not_to have_enqueued_job(Reminders::DeliverJob)

    expect(result.failure?).to be(true)
  end

  it "fails on a blank message" do
    result = described_class.call(user_id: 1, channel_id: 2, message: "  ", duration: "1h")
    expect(result.failure?).to be(true)
  end
end
