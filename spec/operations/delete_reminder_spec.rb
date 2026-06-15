require "rails_helper"

RSpec.describe DeleteReminder do
  let(:reminder) do
    create(:reminder, user_id: 1, channel_id: 2, remind_at: 1.hour.from_now, message: "x")
  end

  it "deletes the owner's reminder" do
    result = described_class.call(reminder_id: reminder.id, user_id: 1)
    expect(result.success?).to be(true)
    expect(Reminders::Reminder.exists?(reminder.id)).to be(false)
  end

  it "refuses to delete another user's reminder" do
    result = described_class.call(reminder_id: reminder.id, user_id: 999)
    expect(result.failure?).to be(true)
    expect(Reminders::Reminder.exists?(reminder.id)).to be(true)
  end

  it "fails for a missing reminder" do
    result = described_class.call(reminder_id: "rmd_missing", user_id: 1)
    expect(result.failure?).to be(true)
  end
end
