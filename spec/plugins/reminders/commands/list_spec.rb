require "rails_helper"

RSpec.describe Reminders::List do
  let(:event) { double("event", user: double(id: 1), respond: nil) }

  it "reports when there are no reminders" do
    expect(event).to receive(:respond).with(hash_including(content: a_string_including("no active reminders")))
    described_class.new(event).execute
  end

  it "lists the user's reminders" do
    create(:reminder, user_id: 1, channel_id: 2, remind_at: 1.hour.from_now, message: "buy milk")
    expect(event).to receive(:respond).with(hash_including(content: a_string_including("buy milk")))
    described_class.new(event).execute
  end
end
