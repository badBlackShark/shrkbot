require "rails_helper"

RSpec.describe Ops::ServerConfiguration::Ensure do
  subject(:result) { described_class.call(discord_id:) }

  let(:discord_id) { 42 }
  let!(:logging) { create(:plugin, key: "logging", name: "Logging") }
  let!(:welcomes) { create(:plugin, key: "welcomes", name: "Welcomes") }

  it "creates a server configuration when none exists" do
    expect { result }.to change { ServerConfiguration.where(discord_id:).count }.from(0).to(1)
  end

  it "seeds an activation per plugin, all disabled" do
    activations = result.value.plugin_activations.joins(:plugin)

    expect(activations.find_by(plugins: {key: "logging"}).enabled).to be(false)
    expect(activations.find_by(plugins: {key: "welcomes"}).enabled).to be(false)
  end

  it "creates the plugin settings rows so they always exist" do
    config = result.value

    expect(config.logging_setting).to be_present
    expect(config.role_setting).to be_present
    expect(config.welcome_settings).to be_present
  end

  context "when a concurrent insert wins the race" do
    it "returns the already-created configuration instead of raising" do
      existing = create(:server_configuration, discord_id:)
      allow(ServerConfiguration).to receive(:find_or_create_by!).and_raise(ActiveRecord::RecordNotUnique)

      expect(result.value).to eq(existing)
    end
  end

  context "when the configuration already exists with a manually toggled activation" do
    let(:config) { described_class.call(discord_id:).value }

    before do
      config.welcome_settings.update!(channel_id: 42)
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
