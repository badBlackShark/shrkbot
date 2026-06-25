# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Reminders::Delete do
  subject(:result) { described_class.call(reminder:) }

  let(:reminder) do
    create(:reminder, user_id: 1, channel_id: 2, remind_at: 1.hour.from_now, message: "x")
  end

  it "destroys the given reminder" do
    expect(result.success?).to be(true)
    expect(Reminders::Reminder.exists?(reminder.id)).to be(false)
  end
end
