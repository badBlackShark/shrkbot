# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Logging::ConfigForm do
  subject(:html) do
    described_class.new(server_configuration: config).render_in(view_context)
  end

  let(:view_context) { ApplicationController.new.view_context }
  let(:config) { create(:server_configuration) }

  before do
    create(:logging_settings, server_configuration: config)
  end

  it "renders the channel card with the required marker" do
    expect(html).to include("This setting is required to enable the plugin")
  end

  it "shows the none-message when no channels have synced" do
    expect(html).to include("No channels have synced yet")
  end

  describe "the public-channel warning" do
    let(:warning) { Nokogiri::HTML5.fragment(html).at_css("[data-controller=live-warning]") }

    it "watches the channel field for a public pick" do
      expect(JSON.parse(warning["data-live-warning-fields-value"])).to eq(["logging[channel_id]"])
      expect(warning["data-live-warning-rule-value"]).to eq("includes-any")
    end

    context "when the saved channel is public" do
      let(:channel) { create(:server_channel, server_configuration: config) }

      before do
        Logging::Settings.find_by!(server_configuration: config).update!(channel_id: channel.discord_id)
      end

      it "renders the warning" do
        expect(warning.key?("hidden")).to be(false)
      end
    end

    context "when the saved channel is private" do
      let(:channel) { create(:server_channel, server_configuration: config) }

      before do
        create(:channel_overwrite, server_channel: channel, target_id: config.discord_id, deny: ServerChannel::VIEW_CHANNEL)
        Logging::Settings.find_by!(server_configuration: config).update!(channel_id: channel.discord_id)
      end

      it "hides the warning" do
        expect(warning.key?("hidden")).to be(true)
      end
    end
  end
end
