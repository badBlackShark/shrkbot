# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::ConfigPage do
  include_context "component view context"

  subject(:html) do
    described_class.new(
      header: Components::ConfigPageHeader.new(
        icon: "bell",
        title: "Reminders",
        description: "Manage reminders."
      ),
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

  context "when channel_lost is true" do
    subject(:html) do
      described_class.new(
        header: Components::ConfigPageHeader.new(
          icon: "bell",
          title: "Reminders",
          description: "Manage reminders."
        ),
        server_configuration: config,
        url: "/servers/900000001/reminders",
        channel_lost: true
      ).render_in(view_context) { "" }
    end

    let(:name) { "Dev Refuge" }

    it "renders the channel-lost warning banner" do
      expect(html).to include("The channel you configured for Reminders was deleted")
    end
  end

  context "when channel_lost is false (default)" do
    let(:name) { "Dev Refuge" }

    it "does not render the channel-lost warning banner" do
      expect(html).not_to include("The channel you configured for")
    end
  end

  context "when gated (enabled) and channel_lost" do
    subject(:html) do
      described_class.new(
        header: Components::ConfigPageHeader.new(
          icon: "scroll",
          title: "Logging",
          description: "Record moderation events."
        ),
        server_configuration: config,
        url: "/servers/900000001/logging",
        gate: {field: "logging[enabled]", enabled: true, message: "off"},
        channel_lost: true
      ).render_in(view_context) { "" }
    end

    let(:name) { "Dev Refuge" }

    it "renders the banner inside the gated body" do
      expect(html).to include("The channel you configured for Logging was deleted")
    end
  end
end
