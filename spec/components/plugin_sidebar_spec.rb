# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::PluginSidebar do
  include_context "component view context"

  subject(:html) do
    described_class.new(server_configuration: config, active_key: :logging).render_in(view_context)
  end

  let(:config) { create(:server_configuration, discord_id: 900_000_001, name:) }

  context "when the server configuration has a name" do
    let(:name) { "Dev Refuge" }

    it "shows the server name in the back-link" do
      expect(html).to include("Dev Refuge")
    end
  end

  context "when the server configuration has no name" do
    let(:name) { nil }

    it "falls back to the generic dashboard label" do
      expect(html).to include("Dashboard")
    end
  end
end
