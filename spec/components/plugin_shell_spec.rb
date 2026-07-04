# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::PluginShell do
  include_context "component view context"

  subject(:html) do
    described_class.new(
      user:,
      server_configuration: config,
      active_key: :logging
    ).render_in(view_context) { "block content" }
  end

  let(:user) { create(:user) }
  let(:config) { create(:server_configuration, discord_id: 900_000_001, name:) }

  context "when the server configuration has a name" do
    let(:name) { "Dev Refuge" }

    it "renders the sidebar with the server name" do
      expect(html).to include("Dev Refuge")
    end

    it "yields the block content" do
      expect(html).to include("block content")
    end
  end

  context "when the server configuration has no name" do
    let(:name) { nil }

    it "renders the sidebar with the fallback dashboard label" do
      expect(html).to include("Dashboard")
    end
  end
end
