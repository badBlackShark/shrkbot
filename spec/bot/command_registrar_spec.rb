require "rails_helper"

RSpec.describe CommandRegistrar do
  # Records what the registrar pushes, standing in for Discordrb::Bot. We assert
  # WE call the boundary correctly; discordrb's own behavior is not under test.
  let(:fake_bot) do
    Class.new do
      attr_reader :defined, :handlers

      def initialize
        @defined = []
        @handlers = {}
        @autocompletes = []
      end

      attr_reader :autocompletes

      def register_application_command(name, description, server_id:, default_member_permissions:, contexts:, &block)
        @defined << {name:, description:, server_id:, default_member_permissions:, contexts:, block:}
      end

      def application_command(name, &block)
        @handlers[name] = block
      end

      # Mirrors discordrb: the positional name matches the focused OPTION; the
      # command is filtered via attributes[:command_name].
      def autocomplete(name = nil, attributes = {}, &block)
        @autocompletes << {name:, attributes:, block:}
      end
    end.new
  end

  let(:guild_cmd) do
    Class.new(BaseCommand) do
      command_name :ping
      description "alive?"
      requires_permissions :manage_server
      register_in :guild
    end
  end

  let(:global_cmd) do
    Class.new(BaseCommand) do
      command_name :info
      description "about"
      register_in :global
    end
  end

  it "registers a :guild command against the test server with its permissions" do
    described_class.new(fake_bot, commands: [guild_cmd], test_server_id: "srv_123").register_all
    cmd = fake_bot.defined.sole
    expect(cmd[:name]).to eq(:ping)
    expect(cmd[:server_id]).to eq("srv_123")
    expect(cmd[:default_member_permissions]).to eq([:manage_server])
    expect(cmd[:contexts]).to be_nil
  end

  it "registers a :global command with no server and DM-capable contexts" do
    described_class.new(fake_bot, commands: [global_cmd], test_server_id: "srv_123").register_all
    cmd = fake_bot.defined.sole
    expect(cmd[:server_id]).to be_nil
    expect(cmd[:contexts]).to eq(%i[server bot_dm])
    expect(cmd[:default_member_permissions]).to be_nil # empty perms → nil, not []
  end

  it "registers a :global command to the test server when instant_global (dev)" do
    described_class.new(fake_bot, commands: [global_cmd], test_server_id: "srv_123", instant_global: true).register_all
    cmd = fake_bot.defined.sole
    expect(cmd[:server_id]).to eq("srv_123") # guild-scoped → appears instantly
    expect(cmd[:contexts]).to be_nil # guild commands are server-only
  end

  it "attaches a handler that dispatches to the command class" do
    described_class.new(fake_bot, commands: [global_cmd], test_server_id: "x").register_all
    expect(fake_bot.handlers.key?(:info)).to be(true)

    event = double("event", user: double(id: 1), respond: nil)
    allow(BotConfig).to receive(:owner_id).and_return(nil)
    expect(global_cmd).to receive(:dispatch).with(event)
    fake_bot.handlers[:info].call(event)
  end

  it "attaches an autocomplete handler filtered by command_name (not focused option) only for commands that define #autocomplete" do
    picker = Class.new(BaseCommand) do
      command_name :pick
      description "d"
      register_in :global
      def autocomplete = nil
    end

    described_class.new(fake_bot, commands: [picker, global_cmd], test_server_id: "x").register_all

    expect(fake_bot.autocompletes.size).to eq(1) # global_cmd has no #autocomplete
    reg = fake_bot.autocompletes.first
    expect(reg[:attributes][:command_name]).to eq(:pick) # matches the command…
    expect(reg[:name]).to be_nil # …not a focused-option name
  end

  it "skips commands that are not registrable" do
    abstract = Class.new(BaseCommand) # no command_name
    described_class.new(fake_bot, commands: [abstract], test_server_id: "x").register_all
    expect(fake_bot.defined).to be_empty
  end

  context "without a test server id" do
    it "skips :guild commands (and their handler) rather than registering them globally" do
      allow(Rails.logger).to receive(:warn)
      described_class.new(fake_bot, commands: [guild_cmd], test_server_id: nil).register_all

      expect(fake_bot.defined).to be_empty
      expect(fake_bot.handlers).to be_empty
      expect(Rails.logger).to have_received(:warn).with(/skipping :guild command \/ping/)
    end

    it "still registers :global commands" do
      described_class.new(fake_bot, commands: [global_cmd], test_server_id: nil).register_all
      expect(fake_bot.defined.map { |c| c[:name] }).to eq([:info])
    end
  end
end
