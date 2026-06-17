require "rails_helper"

RSpec.describe Reminders::List do
  subject(:execute) { described_class.new(event).execute }

  let(:event) { double("event", user: double(id: 1), respond: nil) }

  context "with no reminders" do
    it "reports an empty list" do
      expect(event).to receive(:respond).with(hash_including(content: a_string_including("no active reminders")))
      execute
    end
  end

  context "with reminders" do
    before { create(:reminder, user_id: 1, channel_id: 2, remind_at: 1.hour.from_now, message: "buy milk") }

    it "lists them" do
      expect(event).to receive(:respond).with(hash_including(content: a_string_including("buy milk")))
      execute
    end
  end
end
