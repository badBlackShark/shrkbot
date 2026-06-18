require "rails_helper"

RSpec.describe Reminders::Unremind do
  describe "#execute" do
    subject(:execute) { described_class.new(event).execute }

    let(:event) { double("event", user: double(id: 1), options: {"reminder" => "rmd_x"}, respond: nil) }

    it "cancels the chosen reminder via Ops::Reminders::Delete" do
      expect(Ops::Reminders::Delete).to receive(:call).with(reminder_id: "rmd_x", user_id: 1)
        .and_return(Ops::ApplicationOperation::Result.new(true, nil, []))
      expect(event).to receive(:respond).with(hash_including(content: a_string_including("cancelled")))
      execute
    end

    it "surfaces the failure message when the cancellation is rejected" do
      allow(Ops::Reminders::Delete).to receive(:call)
        .and_return(Ops::ApplicationOperation::Result.new(false, nil, ["not your reminder"]))
      expect(event).to receive(:respond).with(hash_including(content: a_string_including("not your reminder")))
      execute
    end
  end

  describe "command options" do
    it "declares an autocompleted reminder input" do
      opts = double("options")
      allow(opts).to receive(:string)

      described_class.registration.options_block.call(opts)

      expect(opts).to have_received(:string).with("reminder", anything, hash_including(required: true, autocomplete: true))
    end
  end

  describe "#autocomplete" do
    subject(:autocomplete) { described_class.new(ac_event).autocomplete }

    let(:ac_event) { double("autocomplete_event", user: double(id: 1)) }

    context "with reminders belonging to several users" do
      let!(:mine) { create(:reminder, user_id: 1, message: "walk dog", remind_at: Time.utc(2026, 6, 16, 14, 30)) }

      before do
        create(:reminder, user_id: 999, message: "not mine")
      end

      it "offers only the requesting user's reminders, labelled with message + absolute time" do
        expect(ac_event).to receive(:respond) do |choices:|
          expect(choices).to match([{name: a_string_including("walk dog", "14:30"), value: mine.id}])
        end
        autocomplete
      end
    end

    context "with same-text reminders differing only by time" do
      let!(:early) { create(:reminder, user_id: 1, message: "ping", remind_at: Time.utc(2026, 6, 16, 9, 0)) }
      let!(:late) { create(:reminder, user_id: 1, message: "ping", remind_at: Time.utc(2026, 6, 17, 9, 0)) }

      it "includes both (no key collapse)" do
        captured = nil
        allow(ac_event).to receive(:respond) { |choices:| captured = choices }
        autocomplete

        expect(captured.map { |c| c[:value] }).to contain_exactly(early.id, late.id)
        expect(captured.map { |c| c[:name] }).to all(include("ping"))
      end
    end
  end
end
