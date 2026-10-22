# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reminders::Edit do
  describe "#execute" do
    subject(:execute) { described_class.new(event).execute }

    let(:event) do
      double("event", user: double(id: requester_id), options: {"reminder" => reminder_id, "message" => new_message}, respond: nil)
    end
    let!(:reminder) { create(:reminder, user_id: 1, channel_id: 2, remind_at: 1.hour.from_now, message: "x") }
    let(:requester_id) { 1 }
    let(:reminder_id) { reminder.id }
    let(:new_message) { "walk the dog" }

    context "when the requester owns the reminder" do
      it "changes the text and confirms it" do
        expect(event).to receive(:respond).with(hash_including(content: a_string_including("walk the dog")))
        execute
        expect(reminder.reload.message).to eq("walk the dog")
      end
    end

    context "when the reminder belongs to another user" do
      let(:requester_id) { 999 }

      it "leaves it intact and reports it doesn't exist" do
        expect(event).to receive(:respond).with(hash_including(content: a_string_including("doesn't exist")))
        execute
        expect(reminder.reload.message).to eq("x")
      end
    end

    context "when the reminder does not exist" do
      let(:reminder_id) { "rmd_missing" }

      it "reports it doesn't exist" do
        expect(event).to receive(:respond).with(hash_including(content: a_string_including("doesn't exist")))
        execute
      end
    end

    context "when the new message is blank" do
      let(:new_message) { "  " }

      it "reports the error and keeps the old text" do
        expect(event).to receive(:respond).with(hash_including(content: a_string_including("needs a message")))
        execute
        expect(reminder.reload.message).to eq("x")
      end
    end
  end

  describe "command options" do
    it "declares an autocompleted reminder input and a required message input" do
      opts = double("options")
      allow(opts).to receive(:string)

      described_class.registration.options_block.call(opts)

      expect(opts).to have_received(:string).with("reminder", anything, hash_including(required: true, autocomplete: true))
      expect(opts).to have_received(:string).with("message", anything, hash_including(required: true))
    end
  end
end
