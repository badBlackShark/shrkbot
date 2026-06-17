require "rails_helper"

RSpec.describe EventRegistrar do
  subject(:register_all) { described_class.new(fake_bot, events:).register_all }

  # Records what the registrar binds, standing in for Discordrb::Bot.
  let(:fake_bot) do
    Class.new do
      attr_reader :handlers

      def initialize
        @handlers = {}
      end

      def member_join(&block)
        @handlers[:member_join] = block
      end
    end.new
  end

  context "with a registrable event" do
    let(:event_class) do
      Class.new(BaseEvent) do
        on :member_join
        def handle
        end
      end
    end
    let(:events) { [event_class] }

    it "binds it to its discordrb handler and dispatches to the class" do
      register_all
      expect(fake_bot.handlers.key?(:member_join)).to be(true)

      incoming = double("event")
      expect(event_class).to receive(:dispatch).with(incoming)
      fake_bot.handlers[:member_join].call(incoming)
    end
  end

  context "with an event missing an `on` declaration" do
    let(:events) { [Class.new(BaseEvent)] }

    it "skips it" do
      register_all
      expect(fake_bot.handlers).to be_empty
    end
  end
end
