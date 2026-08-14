# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::ServerConfiguration::Previews::Create do
  subject(:result) { described_class.call }

  let!(:plugins) do
    Plugin.insert_all(
      PluginCatalog.all.map do |definition|
        {key: definition.key.to_s, name: definition.name, description: definition.description, created_at: Time.current, updated_at: Time.current}
      end
    )
  end

  it "creates a server configuration at the preview data's negative discord_id" do
    expect { result }.to change {
      ServerConfiguration.where(discord_id: PreviewData.guild[:discord_id]).count
    }.from(0).to(1)
  end

  it "creates a preview configuration" do
    expect(result.value.preview?).to be(true)
  end

  it "creates every channel from the preview data" do
    config = result.value

    expect(config.server_channels.pluck(:discord_id)).to match_array(PreviewData.channels.map { |c| c[:discord_id] })
  end

  it "creates every role from the preview data" do
    config = result.value

    expect(config.server_roles.pluck(:discord_id)).to match_array(PreviewData.roles.map { |r| r[:discord_id] })
  end

  describe "plugin activation and prerequisites" do
    subject(:config) { result.value }

    it "enables every non-bespoke plugin and satisfies its prerequisite chain" do
      activations = config.plugin_activations.includes(:plugin).index_by { |activation| activation.plugin.key }
      enabled_keys = config.enabled_plugin_keys

      PluginCatalog.all.reject(&:bespoke).each do |definition|
        expect(activations.fetch(definition.key).enabled).to be(true)
        expect(definition.prerequisites_met?(config, enabled_keys:)).to be(true)
      end
    end
  end

  describe "calling it twice" do
    it "does not duplicate role sets" do
      described_class.call

      expect { described_class.call }.not_to change(Roles::Set, :count)
    end

    it "does not duplicate channels" do
      described_class.call

      expect { described_class.call }.not_to change(ServerChannel, :count)
    end
  end

  describe "the bot config bus" do
    before do
      allow(Bot::ConfigBus).to receive(:publish)
    end

    it "is never published to, because no bot is connected to a preview guild" do
      result

      expect(Bot::ConfigBus).not_to have_received(:publish)
    end
  end
end
