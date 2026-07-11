# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe Bot::CommandRegistrar do
  let(:fake_bot) do
    Class.new do
      attr_reader :handlers, :autocompletes

      def initialize
        @handlers = {}
        @autocompletes = []
      end

      def application_command(name, &block)
        @handlers[name] = block
      end

      def autocomplete(name = nil, attributes = {}, &block)
        @autocompletes << {name:, attributes:, block:}
      end

      def token
        "Bot test-token"
      end

      def profile
        Struct.new(:id).new(1)
      end
    end.new
  end

  let(:guild_cmd) do
    Class.new(Bot::BaseCommand) do
      command_name :ping
      description "alive?"
      requires_permissions :manage_server
      register_in :guild
    end
  end

  let(:global_cmd) do
    Class.new(Bot::BaseCommand) do
      command_name :info
      description "about"
      register_in :global
    end
  end

  context "handler dispatch" do
    subject(:register_all) { described_class.new(fake_bot, commands: [guild_cmd, global_cmd]).register_all }

    before do
      allow(Discordrb::API::Application).to receive(:bulk_overwrite_global_commands)
      allow(Rails.env).to receive(:development?).and_return(false)
    end

    it "attaches handlers for all registrable commands" do
      register_all
      expect(fake_bot.handlers.key?(:ping)).to be(true)
      expect(fake_bot.handlers.key?(:info)).to be(true)
    end

    it "dispatches to the command class on invocation" do
      register_all
      event = double("event", user: double(id: 1), respond: nil)
      expect(global_cmd).to receive(:dispatch).with(event)
      fake_bot.handlers[:info].call(event)
    end
  end

  context "with define_commands true and env not development" do
    subject(:register_all) do
      described_class.new(fake_bot, commands: [guild_cmd, global_cmd]).register_all
    end

    before do
      allow(Rails.env).to receive(:development?).and_return(false)
    end

    it "calls bulk_overwrite_global_commands with only global command payloads" do
      captured_payloads = nil
      allow(Discordrb::API::Application).to receive(:bulk_overwrite_global_commands) do |_token, _id, payloads|
        captured_payloads = payloads
      end

      register_all

      expect(captured_payloads).not_to be_nil
      names = captured_payloads.map { |p| p[:name] }
      expect(names).to include(:info)
      expect(names).not_to include(:ping)
    end
  end

  context "in development environment" do
    subject(:register_all) do
      described_class.new(fake_bot, commands: [global_cmd]).register_all
    end

    before do
      allow(Rails.env).to receive(:development?).and_return(true)
    end

    it "does not call bulk_overwrite_global_commands" do
      expect(Discordrb::API::Application).not_to receive(:bulk_overwrite_global_commands)
      register_all
    end
  end

  context "with define_commands: false (a non-first shard)" do
    subject(:register_all) do
      described_class.new(fake_bot, commands: [global_cmd], define_commands: false).register_all
    end

    it "attaches the handler without calling bulk_overwrite_global_commands" do
      expect(Discordrb::API::Application).not_to receive(:bulk_overwrite_global_commands)
      register_all
      expect(fake_bot.handlers.key?(:info)).to be(true)
    end
  end

  context "autocomplete registration" do
    let(:picker) do
      Class.new(Bot::BaseCommand) do
        command_name :pick
        description "d"
        register_in :global
        def autocomplete
        end
      end
    end

    subject(:register_all) do
      allow(Discordrb::API::Application).to receive(:bulk_overwrite_global_commands)
      allow(Rails.env).to receive(:development?).and_return(false)
      described_class.new(fake_bot, commands: [picker, global_cmd]).register_all
    end

    it "attaches an autocomplete handler only for commands that define #autocomplete" do
      register_all
      expect(fake_bot.autocompletes.size).to eq(1)
      reg = fake_bot.autocompletes.first
      expect(reg[:attributes][:command_name]).to eq(:pick)
      expect(reg[:name]).to be_nil
    end
  end

  context "with non-registrable commands" do
    subject(:register_all) do
      described_class.new(fake_bot, commands: [Class.new(Bot::BaseCommand)]).register_all
    end

    before do
      allow(Rails.env).to receive(:development?).and_return(false)
      allow(Discordrb::API::Application).to receive(:bulk_overwrite_global_commands)
    end

    it "skips them" do
      register_all
      expect(fake_bot.handlers).to be_empty
    end
  end
end
