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
  end
end
