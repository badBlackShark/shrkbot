# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::SubPluginRow do
  include_context "component view context"

  let(:config) { create(:server_configuration, discord_id: 900_000_001) }
  let(:fragment) { Nokogiri::HTML.fragment(html) }

  let(:row_attrs) do
    {
      key: :spam_protection,
      name: "Cross-Channel Spam Guard",
      description: "Purges the same message posted across several channels within seconds.",
      enabled: true,
      configured: true
    }
  end

  let(:base_attrs) do
    {
      server_configuration: config,
      row: SubPluginStatus::Row.new(**row_attrs)
    }
  end

  def with_row(**overrides)
    base_attrs.merge(row: SubPluginStatus::Row.new(**row_attrs.merge(overrides)))
  end

  subject(:html) { described_class.new(**base_attrs).render_in(view_context) }

  context "when the plugin was added recently" do
    before do
      allow(PluginCatalog).to receive_messages(recently_added?: true, beta?: false)
    end

    it "shows the New badge" do
      expect(html).to include("New</span>")
    end
  end

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

    it "submits the toggle through the stub form" do
      expect(fragment.at_css("input[type=checkbox][name=enabled]")["form"]).to eq("spam_protection-overview-toggle-form")
    end

    it "sends nothing but the enabled flag" do
      expect(fragment.css("input[form]").map { |input| input["name"] }.uniq).to eq(["enabled"])
    end
  end

  context "when needs setup (not configured, not enabled)" do
    subject(:html) do
      described_class.new(**with_row(enabled: false, configured: false)).render_in(view_context)
    end

    it "renders the Needs setup badge" do
      expect(html).to include("Needs setup")
    end

    it "renders the toggle as disabled with the dashboard hint" do
      expect(html).to include("disabled").and include(CGI.escapeHTML(I18n.t("components.plugin_row.needs_setup_hint")))
    end

    it "still renders the Configure link" do
      expect(html).to include("Configure")
    end
  end

  context "when enabled but its setup was lost" do
    subject(:html) do
      described_class.new(**with_row(enabled: true, configured: false)).render_in(view_context)
    end

    it "leaves the toggle interactive so it can be turned off" do
      expect(fragment.css("input[type=checkbox][disabled]")).to be_empty
    end
  end

  context "for spam_protection when disabled but configured" do
    subject(:html) do
      described_class.new(**with_row(enabled: false, configured: true)).render_in(view_context)
    end

    it "renders the Disabled badge" do
      expect(html).to include("Disabled")
    end

    it "leaves the toggle interactive" do
      expect(fragment.css("input[type=checkbox][disabled]")).to be_empty
    end
  end

  context "when the server configuration is a preview" do
    let(:config) { create(:server_configuration, :preview) }

    it "locks the toggle" do
      expect(fragment.css("input[type=checkbox][disabled]")).not_to be_empty
    end

    it "says why in the tooltip" do
      expect(html).to include(CGI.escapeHTML(I18n.t("components.plugin_row.preview_locked")))
    end
  end
end
