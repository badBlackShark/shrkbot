# frozen_string_literal: true

require "rails_helper"

RSpec.describe Roles::MenuBackfill do
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
  end

  context "with an unposted set in an enabled roles plugin on a bot-shard guild" do
    let!(:set) { create(:role_set, role_setting: setting, message_id: nil) }

    it "calls Post for the set" do
      handle
      expect(Ops::Roles::Messages::Post).to have_received(:call).with(bot:, role_set: set)
    end
  end

  context "when the set already has a message_id" do
    let!(:set) { create(:role_set, role_setting: setting, message_id: 999) }

    it "skips the set" do
      handle
      expect(Ops::Roles::Messages::Post).not_to have_received(:call)
    end
  end

  context "when the roles plugin is disabled" do
    before { activation.update!(enabled: false) }

    let!(:set) { create(:role_set, role_setting: setting, message_id: nil) }

    it "skips the set" do
      handle
      expect(Ops::Roles::Messages::Post).not_to have_received(:call)
    end
  end

  context "when the guild is not in bot.servers" do
    before { allow(bot).to receive(:servers).and_return({}) }

    let!(:set) { create(:role_set, role_setting: setting, message_id: nil) }

    it "skips the set" do
      handle
      expect(Ops::Roles::Messages::Post).not_to have_received(:call)
    end
  end
end
