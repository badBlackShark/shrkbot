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

  context "when the request exposes a server switcher" do
    let(:name) { "Dev Refuge" }
    let!(:other) { create(:server_configuration, discord_id: 900_000_002, name: "Other Guild", member_count: 3) }
    let(:switcher) do
      CachedDashboard.for(
        discord_id: config.discord_id,
        manageable_ids: [config.discord_id, other.discord_id]
      )
    end

    before do
      without_partial_double_verification do
        allow(view_context).to receive(:server_switcher).and_return(switcher)
      end
    end

    it "renders the switcher with the other manageable servers" do
      expect(html).to include("Other Guild")
    end
  end
end
