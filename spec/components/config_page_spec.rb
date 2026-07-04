# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::ConfigPage do
  include_context "component view context"

  subject(:html) do
    described_class.new(
      icon: "bell",
      title: "Reminders",
      description: "Manage reminders.",
      server_configuration: config,
      url: "/servers/900000001/reminders"
    ).render_in(view_context) { "" }
  end

  let(:config) { create(:server_configuration, discord_id: 900_000_001, name:) }

  context "when the server configuration has a name" do
    let(:name) { "Dev Refuge" }

    it "shows the server name in the breadcrumb" do
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
