require "rails_helper"

RSpec.describe PluginActivation do
  subject(:activation) { build(:plugin_activation, server_configuration: server, plugin:, enabled:) }

  let(:server) { create(:server_configuration) }
  let(:plugin) { create(:plugin, key: "welcomes", name: "Welcomes") }

  context "enabling a channel-backed plugin without its channel" do
    let(:enabled) { true }

    it { is_expected.not_to be_valid }
  end

  context "enabling a channel-backed plugin once its channel is set" do
    let(:enabled) { true }

    before do
      server.create_welcome_settings!(channel_id: 5)
    end

    it { is_expected.to be_valid }
  end

  context "disabling, regardless of settings" do
    let(:enabled) { false }

    it { is_expected.to be_valid }
  end
end
