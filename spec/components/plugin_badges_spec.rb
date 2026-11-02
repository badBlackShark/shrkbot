# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::PluginBadges do
  include_context "component view context"

  subject(:html) { described_class.new(key: :roles).render_in(view_context) }

  let(:recently_added) { false }
  let(:beta) { false }
  let(:owner) { "shark" }

  before do
    allow(PluginCatalog).to receive_messages(recently_added?: recently_added, beta?: beta)
    allow(Bot::Discord::OwnerUsername).to receive(:call).and_return(owner)
  end

  context "when neither applies" do
    it "renders nothing and never asks Discord for the owner" do
      expect(html).to be_blank
      expect(Bot::Discord::OwnerUsername).not_to have_received(:call)
    end
  end

  context "when recently added" do
    let(:recently_added) { true }

    it "renders the New badge" do
      expect(html).to include("New")
      expect(html).not_to include("Beta")
    end
  end

  context "when beta" do
    let(:beta) { true }

    it "renders a focusable Beta badge" do
      expect(html).to include("Beta").and include('tabindex="0"')
    end

    it "names the owner in the tooltip" do
      expect(html).to include("@shark")
    end

    context "when the owner is unknown" do
      let(:owner) { nil }

      it "falls back to the generic hint" do
        expect(html).to include(CGI.escapeHTML(I18n.t("components.plugin_badges.beta_hint_unknown")))
      end
    end
  end
end
