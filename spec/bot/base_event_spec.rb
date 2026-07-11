# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::BaseEvent do
  let(:event) { double("event", bot: double("bot")) }

  def event_class(&body)
    Class.new(described_class) { define_method(:handle, &body) }
  end

  context "when #handle succeeds" do
    subject(:call) { klass.new(event).call }

    let(:handled) { double("handle spy") }
    let(:klass) do
      spy = handled
      event_class { spy.run }
    end

    it "runs #handle" do
      expect(handled).to receive(:run)
      call
    end
  end

  context "when #handle raises" do
    subject(:call) { klass.new(event).call }

    let(:klass) { event_class { raise "boom" } }

    it "reports to the owner and returns nil" do
      expect(Bot::OwnerNotifier).to receive(:report).with(hash_including(error: an_instance_of(RuntimeError)))
      expect(call).to be_nil
    end
  end

  describe ".dispatch" do
    let(:handled) { double("handle spy") }
    let(:klass) do
      spy = handled
      event_class { spy.run }
    end

    it "instantiates the event class and runs #handle" do
      expect(handled).to receive(:run)
      klass.dispatch(event)
    end
  end

  describe "#handle" do
    subject(:klass) { Class.new(described_class) }

    it "is abstract" do
      expect { klass.new(event).handle }.to raise_error(AbstractMethodError)
    end
  end

  describe ".event_attributes" do
    context "without an `on` declaration" do
      let(:klass) { Class.new(described_class) }

      it "defaults to empty" do
        expect(klass.event_attributes).to eq({})
      end
    end

    context "with attributes on the `on` declaration" do
      let(:klass) { Class.new(described_class) { on :button, custom_id: /x/ } }

      it "captures them alongside the events" do
        expect(klass.discord_events).to eq([:button])
        expect(klass.event_attributes).to eq(custom_id: /x/)
      end
    end
  end
end
