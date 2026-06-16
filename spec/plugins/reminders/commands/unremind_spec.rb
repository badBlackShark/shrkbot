require "rails_helper"

RSpec.describe Reminders::Unremind do
  let(:event) { double("event", user: double(id: 1), options: {"reminder" => "rmd_x"}, respond: nil) }

  it "cancels the chosen reminder via Ops::DeleteReminder" do
    expect(Ops::DeleteReminder).to receive(:call).with(reminder_id: "rmd_x", user_id: 1)
      .and_return(Ops::ApplicationOperation::Result.new(true, nil, []))
    expect(event).to receive(:respond).with(hash_including(content: a_string_including("cancelled")))

    described_class.new(event).execute
  end

  describe "#autocomplete" do
    let(:ac_event) { double("autocomplete_event", user: double(id: 1)) }

    it "offers only the requesting user's reminders, labelled with message + absolute time" do
      mine = create(:reminder, user_id: 1, message: "walk dog", remind_at: Time.utc(2026, 6, 16, 14, 30))
      create(:reminder, user_id: 999, message: "not mine")

      expect(ac_event).to receive(:respond) do |choices:|
        expect(choices).to match([{name: a_string_including("walk dog", "14:30"), value: mine.id}])
      end
      described_class.new(ac_event).autocomplete
    end

    it "includes same-text reminders that differ only by time (no key collapse)" do
      early = create(:reminder, user_id: 1, message: "ping", remind_at: Time.utc(2026, 6, 16, 9, 0))
      late = create(:reminder, user_id: 1, message: "ping", remind_at: Time.utc(2026, 6, 17, 9, 0))

      captured = nil
      allow(ac_event).to receive(:respond) { |choices:| captured = choices }
      described_class.new(ac_event).autocomplete

      expect(captured.map { |c| c[:value] }).to contain_exactly(early.id, late.id)
      expect(captured.map { |c| c[:name] }).to all(include("ping"))
    end
  end
end
