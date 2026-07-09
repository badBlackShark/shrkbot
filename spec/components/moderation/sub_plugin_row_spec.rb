# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Moderation::SubPluginRow do
  include_context "component view context"

  let(:config) { create(:server_configuration, discord_id: 900_000_001) }
  let(:spam_settings) { create(:spam_protection_settings, server_configuration: config) }

  let(:base_attrs) do
    {
      server_id: config.discord_id,
      key: :spam_protection,
      name: "Cross-Channel Spam Guard",
      description: "Purges the same message posted across several channels within seconds.",
      enabled: true,
      configured: true,
      settings: spam_settings,
      group_enabled: true
    }
  end

  subject(:html) { described_class.new(**base_attrs).render_in(view_context) }

  context "when enabled and configured" do
    it "renders the Enabled badge" do
      expect(html).to include("Enabled")
    end

    it "renders the Configure link to the sub-plugin path" do
      expect(html).to include("spam_protection")
      expect(html).to include("Configure")
    end

    it "renders a mini-form posting to the sub-plugin path" do
      expect(html).to include("spam_protection")
      expect(html).to include("method")
    end

    it "includes hidden settings fields to preserve current values" do
      expect(html).to include('name="spam_protection[channel_threshold]"')
      expect(html).to include('name="spam_protection[window_seconds]"')
      expect(html).to include('name="spam_protection[similarity]"')
      expect(html).to include('name="spam_protection[action]"')
      expect(html).to include('name="spam_protection[punishment]"')
      expect(html).to include('name="spam_protection[timeout_seconds]"')
    end
  end

  context "when needs setup (not configured, group enabled)" do
    subject(:html) do
      described_class.new(**base_attrs.merge(enabled: false, configured: false)).render_in(view_context)
    end

    it "renders the Needs setup badge" do
      expect(html).to include("Needs setup")
    end

    it "renders an inline warning hint" do
      expect(html).to include("Pick a staff role first.")
    end

    it "renders the toggle as disabled" do
      expect(html).to include("disabled")
    end

    it "still renders the Configure link" do
      expect(html).to include("Configure")
    end
  end

  context "for image_scanning when enabled and configured" do
    let(:image_settings) { create(:image_scanning_settings, server_configuration: config) }

    subject(:html) do
      described_class.new(
        server_id: config.discord_id,
        key: :image_scanning,
        name: "Scam Image Detection",
        description: "Reads the text in images and fingerprints known scam images.",
        enabled: true,
        configured: true,
        settings: image_settings,
        group_enabled: true
      ).render_in(view_context)
    end

    it "includes hidden fields for image scanning settings" do
      expect(html).to include('name="image_scanning[sensitivity]"')
      expect(html).to include('name="image_scanning[action]"')
      expect(html).to include('name="image_scanning[punishment]"')
      expect(html).to include('name="image_scanning[timeout_seconds]"')
      expect(html).to include('name="image_scanning[custom_keyword_min_hits]"')
    end

    it "links the Configure button to the image_scanning path" do
      expect(html).to include("image_scanning")
      expect(html).to include("Configure")
    end
  end

  context "for image_scanning with custom keywords" do
    let(:image_settings) do
      create(:image_scanning_settings, server_configuration: config, custom_keywords: ["free nitro", "click here"])
    end

    subject(:html) do
      described_class.new(
        server_id: config.discord_id,
        key: :image_scanning,
        name: "Scam Image Detection",
        description: "Reads the text in images and fingerprints known scam images.",
        enabled: true,
        configured: true,
        settings: image_settings,
        group_enabled: true
      ).render_in(view_context)
    end

    it "renders each keyword as a hidden field" do
      expect(html).to include('name="image_scanning[custom_keywords][]"')
      expect(html).to include('value="free nitro"')
      expect(html).to include('value="click here"')
    end
  end

  context "for image_scanning when needs setup (not configured, group enabled)" do
    let(:image_settings) { create(:image_scanning_settings, server_configuration: config) }

    subject(:html) do
      described_class.new(
        server_id: config.discord_id,
        key: :image_scanning,
        name: "Scam Image Detection",
        description: "Reads the text in images and fingerprints known scam images.",
        enabled: false,
        configured: false,
        settings: image_settings,
        group_enabled: true
      ).render_in(view_context)
    end

    it "renders the Needs setup badge" do
      expect(html).to include("Needs setup")
    end

    it "renders the inline warning hint" do
      expect(html).to include("Pick a staff role first.")
    end

    it "renders the toggle as disabled" do
      expect(html).to include("disabled")
    end
  end

  context "for spam_protection when disabled but configured" do
    subject(:html) do
      described_class.new(**base_attrs.merge(enabled: false, configured: true)).render_in(view_context)
    end

    it "renders the Disabled badge" do
      expect(html).to include("Disabled")
    end

    it "renders a form with hidden settings fields (not locked)" do
      expect(html).to include('name="spam_protection[channel_threshold]"')
    end

    it "does not render the needs-setup warning" do
      expect(html).not_to include("Pick a staff role first.")
    end
  end

  context "when settings is nil (no settings record yet)" do
    subject(:html) do
      described_class.new(**base_attrs.merge(enabled: false, configured: true, settings: nil)).render_in(view_context)
    end

    it "renders without hidden fields" do
      expect(html).not_to include('name="spam_protection[channel_threshold]"')
    end
  end

  context "when spam_protection settings have match_symbol_only_messages true" do
    before { spam_settings.update!(match_symbol_only_messages: true) }

    subject(:html) { described_class.new(**base_attrs).render_in(view_context) }

    it "renders the match_symbol_only_messages field with value 1" do
      expect(html).to include('name="spam_protection[match_symbol_only_messages]"')
      expect(html).to include('value="1"')
    end
  end
end
