# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reminders::ReminderPicker do
  let(:host_class) { Struct.new(:event) { include Reminders::ReminderPicker } }

  describe "#autocomplete" do
    subject(:autocomplete) { host_class.new(ac_event).autocomplete }

    let(:ac_event) { double("autocomplete_event", user: double(id: 1)) }

    context "with reminders belonging to several users" do
      let!(:mine) { create(:reminder, user_id: 1, message: "walk dog", remind_at: Time.utc(2026, 6, 16, 14, 30)) }

      before do
        create(:reminder, user_id: 999, message: "not mine")
      end

      it "offers only the requesting user's reminders, labeled with message + absolute time" do
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
