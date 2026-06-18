require "rails_helper"

RSpec.describe Ops::Reminders::Create do
  subject(:result) { described_class.call(user_id:, channel_id:, server_id:, message:, duration:) }

  let(:user_id) { 1 }
  let(:channel_id) { 2 }
  let(:server_id) { 3 }
  let(:message) { "ping me" }
  let(:duration) { "1h" }

  it "creates a reminder and schedules delivery for the parsed time" do
    expect {
      result
    }.to have_enqueued_job(Reminders::DeliverJob).with(kind_of(String)).at(a_value_within(1.minute).of(1.hour.from_now))

    expect(result.success?).to be(true)
    expect(result.value.remind_at).to be_within(1.minute).of(1.hour.from_now)
    expect(result.value.message).to eq("ping me")
  end

  context "with a message containing mentions" do
    let(:message) { "@everyone hi" }

    it "sanitizes the message before persisting" do
      expect(result.value.message).not_to include("@everyone")
    end
  end

  context "with an unparseable duration" do
    let(:message) { "x" }
    let(:duration) { "soon" }

    it "fails without creating or scheduling" do
      expect {
        expect { result }.not_to change(Reminders::Reminder, :count)
      }.not_to have_enqueued_job(Reminders::DeliverJob)

      expect(result.failure?).to be(true)
    end
  end

  context "with a blank message" do
    let(:message) { "  " }

    it "fails" do
      expect(result.failure?).to be(true)
    end
  end
end
