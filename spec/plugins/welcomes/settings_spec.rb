# frozen_string_literal: true

require "rails_helper"

RSpec.describe Welcomes::Settings do
  describe ".active_for" do
    subject(:active_setting) { described_class.active_for(discord_id) }

    let(:server) { create(:server_configuration, discord_id: 123) }
    let(:welcomes) { create(:plugin, key: "welcomes", name: "Welcomes") }
    let(:discord_id) { 123 }

    context "when welcomes is enabled for the server" do
      let!(:setting) { create(:welcome_settings, server_configuration: server) }

      before do
        create(:plugin_activation, server_configuration: server, plugin: welcomes, enabled: true)
      end

      it "returns the setting" do
        expect(active_setting).to eq(setting)
      end
    end

    context "when welcomes is disabled" do
      before do
        create(:plugin_activation, server_configuration: server, plugin: welcomes, enabled: false)
        create(:welcome_settings, server_configuration: server)
      end

      it "returns nil" do
        expect(active_setting).to be_nil
      end
    end

    context "for an unknown server" do
      let(:discord_id) { 999 }

      it "returns nil" do
        expect(active_setting).to be_nil
      end
    end
  end
end
