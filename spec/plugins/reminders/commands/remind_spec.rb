# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reminders::Remind do
  subject(:execute) { described_class.new(event).execute }

  let(:options) { {"duration" => "1h", "message" => "hi", "deliver" => "here"} }
  let(:event) do
    double("event", user: double(id: 1), channel_id: 2, server_id: 3, options:, respond: nil)
  end
  let(:success_result) { Ops::ApplicationOperation::Result.new(true, double(remind_at: Time.at(1_000)), []) }

  context "with valid options" do
    it "calls Ops::Reminders::Create with the event's options and confirms" do
      expect(Ops::Reminders::Create).to receive(:call)
        .with(hash_including(user_id: 1, channel_id: 2, server_id: 3, message: "hi", duration: "1h", deliver_via_dm: false))
        .and_return(success_result)
      expect(event).to receive(:respond).with(hash_including(ephemeral: true, content: a_string_including("remind you")))
      execute
    end
  end

  context "when deliver is dm" do
    let(:options) { {"duration" => "1h", "message" => "hi", "deliver" => "dm"} }

    it "maps it to deliver_via_dm: true" do
      expect(Ops::Reminders::Create).to receive(:call).with(hash_including(deliver_via_dm: true)).and_return(success_result)
      execute
    end
  end

  context "when the operation fails" do
    before do
      allow(Ops::Reminders::Create).to receive(:call)
        .and_return(Ops::ApplicationOperation::Result.new(false, nil, ["bad duration"]))
    end

    it "surfaces the failure message" do
      expect(event).to receive(:respond).with(hash_including(content: a_string_including("bad duration")))
      execute
    end
  end

  describe "command options" do
    it "declares the duration, message, and deliver inputs" do
      opts = double("options")
      allow(opts).to receive(:string)

      described_class.registration.options_block.call(opts)

      expect(opts).to have_received(:string).with("duration", anything, hash_including(required: true))
      expect(opts).to have_received(:string).with("message", anything, hash_including(required: true))
      expect(opts).to have_received(:string).with("deliver", anything, hash_including(required: false, choices: anything))
    end
  end
end
