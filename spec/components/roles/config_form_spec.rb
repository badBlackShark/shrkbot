# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Roles::ConfigForm do
  subject(:html) do
    described_class.new(server_configuration: config).render_in(view_context)
  end

  let(:view_context) { ApplicationController.new.view_context }
  let(:config) { create(:server_configuration) }

  before { create(:role_setting, server_configuration: config) }

  it "renders the default channel card without a required marker" do
    expect(html).not_to include("This setting is required to enable the plugin")
  end

  it "shows the none-message when no channels have synced" do
    expect(html).to include("No channels have synced yet")
  end

  context "when a guild has a category with child text channels" do
    before do
      create(:server_channel, server_configuration: config, name: "General", channel_type: 4, discord_id: 900, position: 0)
      create(:server_channel, server_configuration: config, name: "chat", channel_type: 0, discord_id: 901, position: 0, parent_id: 900)
    end

    it "renders without raising NoMethodError" do
      expect { html }.not_to raise_error
    end
  end
end
