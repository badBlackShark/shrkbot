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

  context "without a url" do
    subject(:html) do
      described_class.new(header:, server_configuration: config, url: nil).render_in(view_context) { "Body" }
    end

    it "renders the body with no form and no save bar" do
      expect(html).to include("Body")
      expect(html).not_to include("<form")
      expect(html).not_to include("save-bar")
    end
  end

  context "with a url" do
    it "wraps the page in the settings form and save bar" do
      expect(html).to include("<form").and include("save-bar")
    end
  end

  context "without a banner" do
    it "shows the plugin tile and the title" do
      expect(html).to include("chamfer-tile", "<h1")
    end
  end

  context "with a banner" do
    let(:header) do
      Components::ConfigPageHeader.new(
        icon: "bell",
        title: "Reminders",
        banner: Components::Feeds::TargetBanner.new(
          watch: build(:integration_watch, name: "Hades II", image_url: "https://example.test/game.jpg"),
          source: ::Feeds::Steam
        )
      )
    end

    it "shows the banner instead of the plugin tile and the title row" do
      expect(html).to include("https://example.test/game.jpg", "Hades II")
      expect(html).not_to include("chamfer-tile")
      expect(html).not_to include("Reminders</h1>")
    end
  end

  context "with a header aside" do
    let(:header) do
      Components::ConfigPageHeader.new(
        icon: "bell",
        title: "Reminders",
        description: "Manage reminders.",
        aside: Components::Badge.new(variant: :copper) { "Beside the title" }
      )
    end

    it "renders the aside next to the title" do
      expect(html).to include("Beside the title")
    end
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

    it "renders the save bar" do
      expect(html).to include('data-controller="save-bar"')
    end

    it "renders both state labels, each shown only for its switch state" do
      expect(html).to match(/<span class="hidden [^"]*group-has-\[:checked\]\/enable:inline">Enabled<\/span>/)
      expect(html).to match(/<span class="[^"]*group-has-\[:checked\]\/enable:hidden">Disabled<\/span>/)
    end
  end

  context "when the toggle names its own states" do
    subject(:html) do
      described_class.new(
        header:,
        server_configuration: config,
        url: "/servers/900000001/reminders",
        toggle: {field: "reminders[enabled]", enabled: true, states: {on: "Subscribed", off: "Not subscribed"}}
      ).render_in(view_context) { "" }
    end

    it "swaps the state labels for them" do
      expect(html).to match(/group-has-\[:checked\]\/enable:inline">Subscribed<\/span>/)
      expect(html).to match(/group-has-\[:checked\]\/enable:hidden">Not subscribed<\/span>/)
      expect(html).not_to include("Enabled")
    end
  end

  context "when the toggle is instant" do
    subject(:html) do
      described_class.new(
        header:,
        server_configuration: config,
        url: "/servers/900000001/steam",
        toggle:
      ).render_in(view_context) { "" }
    end

    let(:toggle) { {field: "steam[enabled]", enabled: true, instant: true} }

    it "renders no save bar" do
      expect(html).not_to include('data-controller="save-bar"')
    end

    it "submits the toggle to the page url on change" do
      expect(html).to include('action="/servers/900000001/steam"', "change->toggle#submit")
    end
  end

  context "when the toggle is instant on a preview server" do
    subject(:html) do
      described_class.new(
        header:,
        server_configuration: config,
        url: "/servers/-1/steam",
        toggle:
      ).render_in(view_context) { "" }
    end

    let(:config) { create(:server_configuration, :preview, name:) }
    let(:toggle) { {field: "steam[enabled]", enabled: true, instant: true} }

    context "when the visitor also lacks toggle access" do
      let(:toggle) { {field: "steam[enabled]", enabled: true, instant: true, locked: true, reason: "Only admins can toggle this."} }

      it "names preview mode as the reason, not the access rule" do
        expect(html).to include(ERB::Util.html_escape(I18n.t("components.plugin_row.preview_locked")))
        expect(html).not_to include("Only admins can toggle this.")
      end
    end

    it "renders the toggle disabled" do
      expect(html).to match(/<input type="checkbox"[^>]* disabled/)
    end

    it "shows the preview tooltip" do
      expect(html).to include(ERB::Util.html_escape(I18n.t("components.plugin_row.preview_locked")))
    end

    it "does not submit on change" do
      expect(html).not_to include("change->toggle#submit")
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

    it "submits the current state through a hidden field" do
      expect(html).to include('<input type="hidden" name="reminders[enabled]" value="0"')
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

  context "when a locked toggle names its own states" do
    subject(:html) do
      described_class.new(
        header:,
        server_configuration: config,
        url: "/servers/900000001/reminders",
        toggle: {field: "reminders[enabled]", enabled:, locked: true, reason: "Locked.", states: {on: "Subscribed", off: "Not subscribed"}}
      ).render_in(view_context) { "" }
    end

    context "when on" do
      let(:enabled) { true }

      it "shows the on state" do
        expect(html).to include(">Subscribed</span>")
        expect(html).not_to include("Not subscribed")
      end
    end

    context "when off" do
      let(:enabled) { false }

      it "shows the off state" do
        expect(html).to include(">Not subscribed</span>")
        expect(html).not_to include(">Subscribed</span>")
      end
    end
  end

  context "with prerequisites" do
    subject(:html) do
      described_class.new(
        header:,
        server_configuration: config,
        url: "/servers/900000001/reminders",
        toggle: {field: "reminders[enabled]", enabled: false, locked: true, reason: "Enable Logging first."},
        prerequisites: Components::PrerequisiteSteps.new(
          icon: "scroll",
          title: "Needs Logging",
          steps: [
            Components::PrerequisiteSteps::Step.new(
              message: "Set up Logging first.",
              cta_label: "Set up Logging",
              cta_href: "/servers/900000001/logging"
            )
          ]
        )
      ).render_in(view_context) { "<p>plain body</p>" }
    end

    it "renders the steps with the title" do
      expect(html).to include("Needs Logging")
    end

    it "renders the CTA link" do
      expect(html).to include("Set up Logging")
      expect(html).to include("/servers/900000001/logging")
    end

    it "keeps the body editable" do
      expect(html).to include("plain body")
      expect(html).not_to include("inert")
    end
  end

  context "without prerequisites" do
    subject(:html) do
      described_class.new(
        header:,
        server_configuration: config,
        url: "/servers/900000001/reminders"
      ).render_in(view_context) { "<p>plain body</p>" }
    end

    it "yields the body content directly" do
      expect(html).to include("plain body")
    end
  end

  context "when channel_lost is true" do
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
