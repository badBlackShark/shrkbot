# frozen_string_literal: true

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

      def channel_create(&block)
        @handlers[:channel_create] = block
      end

      def channel_delete(&block)
        @handlers[:channel_delete] = block
      end

      def button(attributes = {}, &block)
        @handlers[:button] = {attributes: attributes, block: block}
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
    let(:incoming) { double("event") }

    it "binds it to its discordrb handler and dispatches to the class" do
      register_all
      expect(fake_bot.handlers.key?(:member_join)).to be(true)
      expect(event_class).to receive(:dispatch).with(incoming)
      fake_bot.handlers[:member_join].call(incoming)
    end
  end

  context "with an event declaring multiple discordrb events" do
    let(:event_class) do
      Class.new(BaseEvent) do
        on :channel_create, :channel_delete
        def handle
        end
      end
    end
    let(:events) { [event_class] }

    it "binds the class to each declared handler" do
      register_all
      expect(fake_bot.handlers.keys).to contain_exactly(:channel_create, :channel_delete)
    end
  end

  context "with an event declaring handler attributes" do
    let(:event_class) do
      Class.new(BaseEvent) do
        on :button, custom_id: /\Aroles:/
        def handle
        end
      end
    end
    let(:events) { [event_class] }
    let(:incoming) { double("event") }

    it "passes the attributes through to the discordrb handler" do
      register_all
      expect(fake_bot.handlers[:button][:attributes]).to eq(custom_id: /\Aroles:/)
      expect(event_class).to receive(:dispatch).with(incoming)
      fake_bot.handlers[:button][:block].call(incoming)
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
