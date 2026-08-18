# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::ServerConfiguration::BespokePluginGrant::Destroy do
  subject(:result) { described_class.call(bespoke_plugin_grant:) }

  let(:server_configuration) { create(:server_configuration) }
  let(:plugin) { create(:plugin, key: "lfg", name: "Looking for Game") }
  let(:bespoke_plugin_grant) { create(:bespoke_plugin_grant, server_configuration:, plugin_key: "lfg") }

  before do
    allow(Bot::ConfigBus).to receive(:sync_commands)
  end

  it "destroys the grant" do
    bespoke_plugin_grant
    expect { result }.to change(BespokePluginGrant, :count).by(-1)
  end

  it "succeeds" do
    expect(result.success?).to be(true)
  end

  it "publishes sync_commands" do
    result

    expect(Bot::ConfigBus).to have_received(:sync_commands).with(server_configuration)
  end

  context "with a matching enabled PluginActivation on that server" do
    let!(:activation) { create(:plugin_activation, server_configuration:, plugin:, enabled: true) }

    it "flips the activation to disabled" do
      result

      expect(activation.reload.enabled).to be(false)
    end
  end

  context "with an activation for the same plugin on a different server" do
    let(:other_server_configuration) { create(:server_configuration) }
    let!(:other_activation) { create(:plugin_activation, server_configuration: other_server_configuration, plugin:, enabled: true) }

    it "leaves the other server's activation alone" do
      result

      expect(other_activation.reload.enabled).to be(true)
    end
  end

  context "with an activation for a different plugin on the same server" do
    let(:other_plugin) { create(:plugin, key: "custom_other", name: "Custom Other") }
    let!(:other_activation) { create(:plugin_activation, server_configuration:, plugin: other_plugin, enabled: true) }

    it "leaves the other plugin's activation alone" do
      result

      expect(other_activation.reload.enabled).to be(true)
    end
  end
end
