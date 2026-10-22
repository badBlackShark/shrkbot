# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Reminders::Update do
  subject(:result) { described_class.call(reminder:, message:) }

  let!(:reminder) { create(:reminder, user_id: 1, channel_id: 2, remind_at: 1.hour.from_now, message: "old") }
  let(:message) { "new text" }

  it "replaces the reminder's message" do
    expect(result.success?).to be(true)
    expect(reminder.reload.message).to eq("new text")
  end

  it "leaves the delivery time alone" do
    expect {
      expect { result }.not_to change { reminder.reload.remind_at }
    }.not_to have_enqueued_job(Reminders::DeliverJob)
  end

  context "with a message containing mentions" do
    let(:message) { "@everyone hi" }

    it "sanitizes the message before persisting" do
      result
      expect(reminder.reload.message).not_to include("@everyone")
    end
  end

  context "with a blank message" do
    let(:message) { "  " }

    it "fails and keeps the old message" do
      expect(result.failure?).to be(true)
      expect(reminder.reload.message).to eq("old")
    end
  end
end
