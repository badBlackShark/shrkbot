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

  context "with the moderation group" do
    let(:name) { "Dev Refuge" }

    it "renders Server Shield as a disclosure group with its sub-plugin links" do
      expect(html).to include("Server Shield")
      expect(html).to include("Overview")
      expect(html).to include("Cross-Channel Spam Guard")
      expect(html).to include("Scam Image Detection")
      expect(html).to include("/servers/900000001/spam_protection")
      expect(html).to include("/servers/900000001/image_scanning")
    end

    context "when a sub-plugin page is active" do
      subject(:html) do
        described_class.new(server_configuration: config, active_key: :image_scanning).render_in(view_context)
      end

      it "auto-expands the group" do
        expect(html).to include("<details open")
      end
    end

    context "when a sub-plugin is configured but disabled (disabled status)" do
      let!(:spam_plugin) { create(:plugin, key: "spam_protection", name: "Cross-Channel Spam Guard") }
      let!(:moderation_plugin) { create(:plugin, key: "moderation", name: "Server Shield") }
      let!(:logging_plugin) { create(:plugin, key: "logging", name: "Logging") }

      before do
        config.create_logging_setting!(channel_id: 111)
        config.create_moderation_settings!(staff_role_id: 555)
        config.create_spam_protection_settings!
        config.create_image_scanning_settings!
        # logging enabled so moderation prereqs pass; spam_protection activation NOT enabled
        create(:plugin_activation, server_configuration: config, plugin: logging_plugin, enabled: false)
          .update_column(:enabled, true)
        create(:plugin_activation, server_configuration: config, plugin: moderation_plugin, enabled: false)
          .update_column(:enabled, true)
        # spam_protection activation exists and is disabled — configured but not enabled
        create(:plugin_activation, server_configuration: config, plugin: spam_plugin, enabled: false)
      end

      subject(:html) do
        described_class.new(server_configuration: config, active_key: :moderation).render_in(view_context)
      end

      it "renders the sidebar without raising" do
        expect(html).to include("Cross-Channel Spam Guard")
      end
    end

    context "when a sub-plugin is enabled (enabled status)" do
      let!(:spam_plugin) { create(:plugin, key: "spam_protection", name: "Cross-Channel Spam Guard") }
      let!(:moderation_plugin) { create(:plugin, key: "moderation", name: "Server Shield") }
      let!(:logging_plugin) { create(:plugin, key: "logging", name: "Logging") }

      before do
        config.create_logging_setting!(channel_id: 111)
        config.create_moderation_settings!(staff_role_id: 555)
        config.create_spam_protection_settings!
        config.create_image_scanning_settings!
        create(:plugin_activation, server_configuration: config, plugin: logging_plugin, enabled: false)
          .update_column(:enabled, true)
        create(:plugin_activation, server_configuration: config, plugin: moderation_plugin, enabled: false)
          .update_column(:enabled, true)
        create(:plugin_activation, server_configuration: config, plugin: spam_plugin, enabled: false)
          .update_column(:enabled, true)
      end

      subject(:html) do
        described_class.new(server_configuration: config, active_key: :moderation).render_in(view_context)
      end

      it "renders the sidebar with the enabled sub-plugin" do
        expect(html).to include("Cross-Channel Spam Guard")
      end
    end
  end
end
