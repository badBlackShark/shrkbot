require "rails_helper"

RSpec.describe Ops::ServerConfiguration::Ensure do
  subject(:result) { described_class.call(discord_id:) }

  let(:discord_id) { 42 }
  let!(:logging) { create(:plugin, key: "logging", name: "Logging", default_enabled: true) }
  let!(:welcomes) { create(:plugin, key: "welcomes", name: "Welcomes", default_enabled: false) }

  it "creates a server configuration when none exists" do
    expect { result }.to change { ServerConfiguration.where(discord_id:).count }.from(0).to(1)
  end

  it "seeds an activation per plugin, all disabled (regardless of default_enabled)" do
    activations = result.value.plugin_activations.joins(:plugin)

    expect(activations.find_by(plugins: {key: "logging"}).enabled).to be(false)
    expect(activations.find_by(plugins: {key: "welcomes"}).enabled).to be(false)
  end

  context "when the configuration already exists with a manually toggled activation" do
    let(:config) { described_class.call(discord_id:).value }

    before do
      config.create_welcome_settings!(channel_id: 42)
      config.plugin_activations.find_by(plugin: welcomes).update!(enabled: true)
    end

    it "is idempotent and preserves the toggle" do
      count_before = config.plugin_activations.count

      result

      expect(config.reload.plugin_activations.count).to eq(count_before)
      expect(config.plugin_activations.find_by(plugin: welcomes).enabled).to be(true)
      expect(ServerConfiguration.where(discord_id:).count).to eq(1)
    end
  end
end
