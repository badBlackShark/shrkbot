# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::ServerConfiguration::BespokePluginGrants::Create do
  subject(:result) { described_class.call(server_configuration:, plugin_key:) }

  let(:server_configuration) { create(:server_configuration) }
  let(:plugin_key) { "lfg" }

  before do
    allow(Bot::ConfigBus).to receive(:sync_commands)
  end

  it "creates the grant" do
    expect(result.value).to be_a(BespokePluginGrant)
    expect(result.value.server_configuration).to eq(server_configuration)
    expect(result.value.plugin_key).to eq("lfg")
  end

  it "succeeds" do
    expect(result.success?).to be(true)
  end

  it "publishes sync_commands" do
    result

    expect(Bot::ConfigBus).to have_received(:sync_commands).with(server_configuration)
  end

  context "when called again for the same server_configuration and plugin_key" do
    before { described_class.call(server_configuration:, plugin_key:) }

    it "does not create a duplicate row" do
      expect { result }.not_to change(BespokePluginGrant, :count)
    end

    it "returns the existing grant" do
      existing = BespokePluginGrant.find_by(server_configuration:, plugin_key:)

      expect(result.value).to eq(existing)
    end
  end
end
