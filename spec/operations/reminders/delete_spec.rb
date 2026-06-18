require "rails_helper"

RSpec.describe Ops::Reminders::Delete do
  subject(:result) { described_class.call(reminder_id:, user_id:) }

  let(:reminder) do
    create(:reminder, user_id: 1, channel_id: 2, remind_at: 1.hour.from_now, message: "x")
  end
  let(:reminder_id) { reminder.id }
  let(:user_id) { 1 }

  context "when the requester owns the reminder" do
    it "deletes it" do
      expect(result.success?).to be(true)
      expect(Reminders::Reminder.exists?(reminder.id)).to be(false)
    end
  end

  context "when the reminder belongs to another user" do
    let(:user_id) { 999 }

    it "refuses and leaves it intact" do
      expect(result.failure?).to be(true)
      expect(Reminders::Reminder.exists?(reminder.id)).to be(true)
    end
  end

  context "when the reminder does not exist" do
    let(:reminder_id) { "rmd_missing" }

    it "fails" do
      expect(result.failure?).to be(true)
    end
  end
end
