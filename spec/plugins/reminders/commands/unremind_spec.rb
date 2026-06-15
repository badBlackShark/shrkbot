require "rails_helper"

RSpec.describe Reminders::Unremind do
  let(:event) { double("event", user: double(id: 1), options: {"reminder" => "rmd_x"}, respond: nil) }

  it "cancels the chosen reminder via DeleteReminder" do
    expect(DeleteReminder).to receive(:call).with(reminder_id: "rmd_x", user_id: 1)
      .and_return(ApplicationOperation::Result.new(true, nil, []))
    expect(event).to receive(:respond).with(hash_including(content: a_string_including("cancelled")))

    described_class.new(event).execute
  end

  describe "#autocomplete" do
    it "offers only the requesting user's reminders, labelled by message" do
      mine = create(:reminder, user_id: 1, channel_id: 2, remind_at: 1.hour.from_now, message: "walk dog")
      create(:reminder, user_id: 999, channel_id: 2, remind_at: 1.hour.from_now, message: "not mine")
      ac_event = double("autocomplete_event", user: double(id: 1))

      expect(ac_event).to receive(:respond).with(choices: {"walk dog" => mine.id})
      described_class.new(ac_event).autocomplete
    end
  end
end
