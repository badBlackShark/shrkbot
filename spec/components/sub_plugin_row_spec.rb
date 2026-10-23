# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::SubPluginRow do
  include_context "component view context"

  let(:config) { create(:server_configuration, discord_id: 900_000_001) }

  let(:toggle_fields) do
    {
      "spam_protection[channel_threshold]" => 3,
      "image_scanning[custom_keywords][]" => ["free nitro", "gift"]
    }
  end

  let(:base_attrs) do
    {
      server_configuration: config,
      key: :spam_protection,
      name: "Cross-Channel Spam Guard",
      description: "Purges the same message posted across several channels within seconds.",
      enabled: true,
      configured: true,
      toggle_fields:,
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

    it "does not render an inline form tag" do
      expect(html).not_to include("<form")
    end

    it "hidden fields carry the stub form id" do
      expect(html).to include('form="spam_protection-overview-toggle-form"')
    end

    it "includes a from_overview hidden field" do
      expect(html).to include('name="from_overview"')
    end

    it "renders each toggle field as a hidden input on the stub form" do
      expect(html).to include('name="spam_protection[channel_threshold]" value="3" form="spam_protection-overview-toggle-form"')
      expect(html).to include('name="image_scanning[custom_keywords][]" value="free nitro" form="spam_protection-overview-toggle-form"')
      expect(html).to include('name="image_scanning[custom_keywords][]" value="gift" form="spam_protection-overview-toggle-form"')
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
    subject(:html) do
      described_class.new(
        server_configuration: config,
        key: :image_scanning,
        name: "Scam Image Detection",
        description: "Reads the text in images and fingerprints known scam images.",
        enabled: true,
        configured: true,
        toggle_fields: {},
        group_enabled: true
      ).render_in(view_context)
    end

    it "links the Configure button to the image_scanning path" do
      expect(html).to include("image_scanning")
      expect(html).to include("Configure")
    end

    it "does not render an inline form tag" do
      expect(html).not_to include("<form")
    end

    it "hidden fields carry the image_scanning stub form id" do
      expect(html).to include('form="image_scanning-overview-toggle-form"')
    end

    it "includes a from_overview hidden field" do
      expect(html).to include('name="from_overview"')
    end
  end

  context "for image_scanning when needs setup (not configured, group enabled)" do
    subject(:html) do
      described_class.new(
        server_configuration: config,
        key: :image_scanning,
        name: "Scam Image Detection",
        description: "Reads the text in images and fingerprints known scam images.",
        enabled: false,
        configured: false,
        toggle_fields: {},
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

    it "renders hidden settings fields (not locked)" do
      expect(html).to include('name="spam_protection[channel_threshold]"')
    end

    it "does not render the needs-setup warning" do
      expect(html).not_to include("Pick a staff role first.")
    end
  end

  context "when toggle_fields is empty (no settings record yet)" do
    subject(:html) do
      described_class.new(**base_attrs.merge(enabled: false, configured: true, toggle_fields: {})).render_in(view_context)
    end

    it "renders without hidden fields" do
      expect(html).not_to include('name="spam_protection[channel_threshold]"')
    end
  end
end
