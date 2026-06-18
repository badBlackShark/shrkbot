require "rails_helper"

RSpec.describe Ops::ServerConfiguration::ReconcileDeletedChannels do
  subject(:result) { described_class.call(server_configuration: server, bot:) }

  let(:server) { create(:server_configuration, discord_id: 1) }
  let(:bot) { double("bot") }
  let(:welcomes) { create(:plugin, key: "welcomes", name: "Welcomes") }

  before do
    allow(OwnerNotifier).to receive(:notify)
    server.create_welcome_settings!(channel_id: 555)
    create(:plugin_activation, server_configuration: server, plugin: welcomes, enabled: true)
  end

  context "when the configured channel is gone from the synced metadata" do
    it "disables the plugin and reports the stale channel" do
      result

      expect(server.plugin_activations.find_by(plugin: welcomes).enabled).to be(false)
      expect(result.value).to eq([555])
    end
  end

  context "when the configured channel still exists" do
    before { create(:server_channel, server_configuration: server, discord_id: 555) }

    it "leaves the plugin enabled" do
      result

      expect(server.plugin_activations.find_by(plugin: welcomes).enabled).to be(true)
      expect(result.value).to be_empty
    end
  end
end
