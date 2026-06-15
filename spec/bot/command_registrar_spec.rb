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
      end

      def register_application_command(name, description, server_id:, default_member_permissions:, contexts:, &block)
        @defined << {name:, description:, server_id:, default_member_permissions:, contexts:, block:}
      end

      def application_command(name, &block)
        @handlers[name] = block
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

  it "attaches a handler that dispatches to the command class" do
    described_class.new(fake_bot, commands: [global_cmd], test_server_id: "x").register_all
    expect(fake_bot.handlers.key?(:info)).to be(true)

    event = double("event", user: double(id: 1), respond: nil)
    allow(BotConfig).to receive(:owner_id).and_return(nil)
    expect(global_cmd).to receive(:dispatch).with(event)
    fake_bot.handlers[:info].call(event)
  end

  it "skips commands that are not registrable" do
    abstract = Class.new(BaseCommand) # no command_name
    described_class.new(fake_bot, commands: [abstract], test_server_id: "x").register_all
    expect(fake_bot.defined).to be_empty
  end
end
