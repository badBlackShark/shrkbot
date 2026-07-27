# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::PluginRow do
  include_context "component view context"

  subject(:html) do
    described_class.new(server_id: 900_000_001, key: :roles, enabled: true, configured: true, manageable:).render_in(view_context)
  end

  let(:manageable) { true }

  context "when the user may configure the plugin" do
    it "links to the configuration page" do
      expect(html).to include(%(href="/servers/900000001/roles"))
    end

    it "leaves the toggle interactive" do
      expect(html).not_to include("disabled")
    end
  end

  context "when the user may not configure the plugin" do
    let(:manageable) { false }

    it "drops the link to the configuration page" do
      expect(html).not_to include(%(href="/servers/900000001/roles"))
    end

    it "disables the toggle and says why" do
      expect(html).to include("disabled")
      expect(html).to include(CGI.escapeHTML(I18n.t("components.plugin_row.not_manageable")))
    end
  end
end
