# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Moderation::ConfigShell do
  include_context "component view context"

  let(:config) { create(:server_configuration, discord_id: 900_000_001, name: "Dev Refuge") }
  let(:header) do
    Components::ConfigPageHeader.new(
      icon: "shield",
      title: "Server Shield",
      description: "Your server's aegis."
    )
  end
  let(:base_toggle) { {field: "moderation[enabled]", enabled: true, locked: false} }

  subject(:html) do
    described_class.new(
      header:,
      server_configuration: config,
      url: "/servers/900000001/moderation",
      toggle: base_toggle
    ).render_in(view_context) { "" }
  end

  it "renders the page header with the title" do
    expect(html).to include("Server Shield")
  end

  it "renders the form with PATCH method and save-bar wiring" do
    expect(html).to include("save-bar")
    expect(html).to include("input-&gt;save-bar#check").or include("input->save-bar#check")
    expect(html).to include("turbo:submit-end-&gt;save-bar#saved").or include("turbo:submit-end->save-bar#saved")
  end

  it "renders the breadcrumb with the server name" do
    expect(html).to include("Dev Refuge")
    expect(html).to include("Server Shield")
  end

  context "when gate is nil" do
    it "yields the body without any gate overlay" do
      html = described_class.new(
        header:,
        server_configuration: config,
        url: "/servers/900000001/moderation",
        toggle: base_toggle
      ).render_in(view_context) { "<p>body content</p>" }
      expect(html).to include("body content")
      expect(html).not_to include("enable-gate")
    end
  end

  context "when gate type is :prereq" do
    subject(:html) do
      described_class.new(
        header:,
        server_configuration: config,
        url: "/servers/900000001/moderation",
        toggle: {field: "moderation[enabled]", enabled: false, locked: true, reason: "Enable Logging first."},
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

    it "renders the PrereqGate with the CTA link" do
      expect(html).to include("Needs Logging")
      expect(html).to include("Set up Logging")
      expect(html).to include("/servers/900000001/logging")
    end
  end

  context "when gate type is :enable" do
    subject(:html) do
      described_class.new(
        header:,
        server_configuration: config,
        url: "/servers/900000001/moderation",
        toggle: {field: "moderation[enabled]", enabled: false, locked: false},
        gate: {
          type: :enable,
          message: "Enable the group to configure sub-plugins."
        }
      ).render_in(view_context) { "" }
    end

    it "renders the EnableGate overlay" do
      expect(html).to include("Enable Server Shield")
    end

    it "wires the form to enable-gate" do
      expect(html).to include("enable-gate")
    end
  end

  context "when toggle is locked" do
    subject(:html) do
      described_class.new(
        header:,
        server_configuration: config,
        url: "/servers/900000001/moderation",
        toggle: {
          field: "moderation[enabled]",
          enabled: false,
          locked: true,
          reason: "Enable the Logging plugin first."
        }
      ).render_in(view_context) { "" }
    end

    it "renders the toggle as disabled" do
      expect(html).to include("disabled")
    end

    it "wraps the toggle in a Tooltip with the reason" do
      expect(html).to include("Enable the Logging plugin first.")
    end
  end

  context "when toggle is locked and currently enabled" do
    subject(:html) do
      described_class.new(
        header:,
        server_configuration: config,
        url: "/servers/900000001/moderation",
        toggle: {
          field: "moderation[enabled]",
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

  context "when header has a badge" do
    subject(:html) do
      header_with_badge = Components::ConfigPageHeader.new(
        icon: "shield",
        title: "Server Shield",
        description: "Your server's aegis.",
        badge: "Beta"
      )
      described_class.new(
        header: header_with_badge,
        server_configuration: config,
        url: "/servers/900000001/moderation",
        toggle: base_toggle
      ).render_in(view_context) { "" }
    end

    it "renders the badge text" do
      expect(html).to include("Beta")
    end
  end

  context "with a breadcrumb_extra" do
    subject(:html) do
      described_class.new(
        header:,
        server_configuration: config,
        url: "/servers/900000001/moderation",
        toggle: base_toggle,
        breadcrumb_extra: "Spam Protection"
      ).render_in(view_context) { "" }
    end

    it "renders the extra breadcrumb label" do
      expect(html).to include("Spam Protection")
    end

    it "links the Server Shield breadcrumb to the moderation overview path" do
      expect(html).to include("/servers/900000001/moderation")
    end
  end
end
