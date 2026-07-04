# frozen_string_literal: true

require "rails_helper"

RSpec.describe Roles::MenuReconcile do
  subject(:handle) { described_class.new(event).handle }

  let(:bot) { double("bot") }
  let(:event) { double("event", bot:) }

  let!(:roles_plugin) { create(:plugin, key: "roles", name: "Roles") }
  let(:config) { create(:server_configuration, discord_id: 900_000_001) }
  let!(:setting) { create(:role_setting, server_configuration: config, channel_id: 111) }
  let!(:activation) { create(:plugin_activation, server_configuration: config, plugin: roles_plugin, enabled: true) }

  before do
    allow(bot).to receive(:servers).and_return({900_000_001 => double("server")})
    allow(Ops::Roles::Messages::Post).to receive(:call)
    allow(Ops::Roles::Messages::Remove).to receive(:call)
  end

  context "with an unposted set in an enabled roles plugin on a bot-shard guild" do
    let!(:set) { create(:role_set, role_setting: setting, message_id: nil) }

    it "calls Post for the set" do
      handle
      expect(Ops::Roles::Messages::Post).to have_received(:call).with(bot:, role_set: set)
    end
  end

  context "when the set already has a message_id (enabled plugin)" do
    let!(:set) { create(:role_set, role_setting: setting, message_id: 999) }

    it "skips Post for the set" do
      handle
      expect(Ops::Roles::Messages::Post).not_to have_received(:call)
    end

    it "does not call Remove for an enabled-plugin set" do
      handle
      expect(Ops::Roles::Messages::Remove).not_to have_received(:call)
    end
  end

  context "when the roles plugin is disabled and the set has a message_id" do
    before do
      activation.update!(enabled: false)
    end

    let!(:set) { create(:role_set, role_setting: setting, message_id: 777) }

    it "calls Remove for the lingering set" do
      handle
      expect(Ops::Roles::Messages::Remove).to have_received(:call).with(bot:, role_set: set)
    end

    it "does not call Post" do
      handle
      expect(Ops::Roles::Messages::Post).not_to have_received(:call)
    end
  end

  context "when the roles plugin is disabled but the set has no message_id" do
    before do
      activation.update!(enabled: false)
    end

    let!(:set) { create(:role_set, role_setting: setting, message_id: nil) }

    it "does not call Remove" do
      handle
      expect(Ops::Roles::Messages::Remove).not_to have_received(:call)
    end
  end

  context "when the guild is not in bot.servers" do
    before do
      allow(bot).to receive(:servers).and_return({})
    end

    let!(:set) { create(:role_set, role_setting: setting, message_id: nil) }

    it "skips the unposted set" do
      handle
      expect(Ops::Roles::Messages::Post).not_to have_received(:call)
    end
  end

  context "when the guild is not in bot.servers and the plugin is disabled with a message_id" do
    before do
      allow(bot).to receive(:servers).and_return({})
      activation.update!(enabled: false)
    end

    let!(:lingering) { create(:role_set, role_setting: setting, message_id: 888) }

    it "skips the lingering set" do
      handle
      expect(Ops::Roles::Messages::Remove).not_to have_received(:call)
    end
  end

  context "with sets from another shard's guild" do
    let(:other_config) { create(:server_configuration, discord_id: 900_000_002) }
    let!(:other_setting) { create(:role_setting, server_configuration: other_config, channel_id: 222) }
    let!(:other_activation) { create(:plugin_activation, server_configuration: other_config, plugin: roles_plugin, enabled: false) }
    let!(:other_set) { create(:role_set, role_setting: other_setting, message_id: 555) }

    it "does not call Remove for the other shard's lingering set" do
      handle
      expect(Ops::Roles::Messages::Remove).not_to have_received(:call)
    end
  end
end
