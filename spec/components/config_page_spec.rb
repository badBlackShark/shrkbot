# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::ConfigPage do
  include_context "component view context"

  let(:config) { create(:server_configuration, discord_id: 900_000_001, name:) }
  let(:name) { "Dev Refuge" }
  let(:header) do
    Components::ConfigPageHeader.new(
      icon: "bell",
      title: "Reminders",
      description: "Manage reminders."
    )
  end

  subject(:html) do
    described_class.new(
      header:,
      server_configuration: config,
      url: "/servers/900000001/reminders"
    ).render_in(view_context) { "" }
  end

  context "when the server configuration has a name" do
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

  context "when no toggle is given" do
    it "does not render an enable control in the header" do
      expect(html).not_to include("enable-gate-target")
      expect(html).not_to include('type="checkbox"')
    end
  end

  context "when toggle is interactive (not locked)" do
    subject(:html) do
      described_class.new(
        header:,
        server_configuration: config,
        url: "/servers/900000001/reminders",
        toggle: {field: "reminders[enabled]", enabled: true, locked: false}
      ).render_in(view_context) { "" }
    end

    it "renders the toggle in the header" do
      expect(html).to include('type="checkbox"')
    end

    it "does not mark the toggle disabled" do
      expect(html).not_to include("disabled")
    end
  end

  context "when toggle is locked" do
    subject(:html) do
      described_class.new(
        header:,
        server_configuration: config,
        url: "/servers/900000001/reminders",
        toggle: {
          field: "reminders[enabled]",
          enabled: false,
          locked: true,
          reason: "Enable the prerequisite first."
        }
      ).render_in(view_context) { "" }
    end

    it "renders the toggle as disabled" do
      expect(html).to include("disabled")
    end

    it "wraps the toggle in a Tooltip with the reason" do
      expect(html).to include("Enable the prerequisite first.")
    end
  end

  context "when toggle is locked and currently enabled" do
    subject(:html) do
      described_class.new(
        header:,
        server_configuration: config,
        url: "/servers/900000001/reminders",
        toggle: {
          field: "reminders[enabled]",
          enabled: true,
          locked: true,
          reason: "Cannot disable while sub-plugins are active."
        }
      ).render_in(view_context) { "" }
    end

    it "shows the enabled label text" do
      expect(html).to include("Enabled")
    end

    it "renders the toggle as disabled" do
      expect(html).to include("disabled")
    end
  end

  context "when gate type is :enable" do
    subject(:html) do
      described_class.new(
        header:,
        server_configuration: config,
        url: "/servers/900000001/reminders",
        toggle: {field: "reminders[enabled]", enabled: false, locked: false},
        gate: {type: :enable, message: "Enable Reminders to configure it."}
      ).render_in(view_context) { "" }
    end

    it "renders the EnableGate overlay" do
      expect(html).to include("Enable Reminders")
    end

    it "wires the form to enable-gate" do
      expect(html).to include("enable-gate")
    end

    it "adds enable-gate stimulus targets to the toggle" do
      expect(html).to include("enable-gate-target")
    end
  end

  context "when gate type is :prereq" do
    subject(:html) do
      described_class.new(
        header:,
        server_configuration: config,
        url: "/servers/900000001/reminders",
        toggle: {field: "reminders[enabled]", enabled: false, locked: true, reason: "Enable Logging first."},
        gate: {
          type: :prereq,
          icon: "scroll",
          title: "Needs Logging",
          message: "Set up Logging first.",
          cta_label: "Set up Logging",
          cta_href: "/servers/900000001/logging"
        }
      ).render_in(view_context) { "" }
    end

    it "renders the PrereqGate with the title" do
      expect(html).to include("Needs Logging")
    end

    it "renders the CTA link" do
      expect(html).to include("Set up Logging")
      expect(html).to include("/servers/900000001/logging")
    end

    it "does not wire the form to enable-gate" do
      expect(html).not_to include("enable-gate")
    end
  end

  context "when ungated (no gate)" do
    it "yields the body content directly" do
      rendered = described_class.new(
        header:,
        server_configuration: config,
        url: "/servers/900000001/reminders"
      ).render_in(view_context) { "<p>plain body</p>" }
      expect(rendered).to include("plain body")
    end
  end

  context "when channel_lost is true (ungated)" do
    subject(:html) do
      described_class.new(
        header:,
        server_configuration: config,
        url: "/servers/900000001/reminders",
        channel_lost: true
      ).render_in(view_context) { "" }
    end

    it "renders the channel-lost warning banner" do
      expect(html).to include("The channel you configured for Reminders was deleted")
    end
  end

  context "when channel_lost is false (default)" do
    it "does not render the channel-lost warning banner" do
      expect(html).not_to include("The channel you configured for")
    end
  end

  context "when gated (:enable) and channel_lost" do
    subject(:html) do
      described_class.new(
        header: Components::ConfigPageHeader.new(
          icon: "scroll",
          title: "Logging",
          description: "Record moderation events."
        ),
        server_configuration: config,
        url: "/servers/900000001/logging",
        toggle: {field: "logging[enabled]", enabled: true, locked: false},
        gate: {type: :enable, message: "off"},
        channel_lost: true
      ).render_in(view_context) { "" }
    end

    it "renders the banner inside the gated body" do
      expect(html).to include("The channel you configured for Logging was deleted")
    end
  end

  context "without parent_crumb" do
    it "breadcrumb ends with the plugin title" do
      expect(html).to include("Reminders")
      expect(html).not_to include("/servers/900000001/moderation")
    end
  end

  context "with parent_crumb" do
    subject(:html) do
      described_class.new(
        header: Components::ConfigPageHeader.new(
          icon: "shield-check",
          title: "Spam Protection",
          description: "Block spam."
        ),
        server_configuration: config,
        url: "/servers/900000001/spam-protection",
        toggle: {field: "spam_protection[enabled]", enabled: true, locked: false},
        parent_crumb: {label: "Server Shield", href: "/servers/900000001/moderation"}
      ).render_in(view_context) { "" }
    end

    it "renders the parent crumb label" do
      expect(html).to include("Server Shield")
    end

    it "links the parent crumb to the provided href" do
      expect(html).to include("/servers/900000001/moderation")
    end

    it "renders the plugin title as the final crumb" do
      expect(html).to include("Spam Protection")
    end
  end

  context "when header has a badge" do
    subject(:html) do
      described_class.new(
        header: Components::ConfigPageHeader.new(
          icon: "bell",
          title: "Reminders",
          description: "Manage reminders.",
          badge: "Beta"
        ),
        server_configuration: config,
        url: "/servers/900000001/reminders"
      ).render_in(view_context) { "" }
    end

    it "renders the badge text" do
      expect(html).to include("Beta")
    end
  end
end
