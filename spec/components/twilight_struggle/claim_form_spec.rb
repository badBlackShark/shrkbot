# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::TwilightStruggle::ClaimForm do
  include Rails.application.routes.url_helpers

  include_context "component view context"

  subject(:html) { described_class.new(tournament:, servers:).render_in(view_context) }

  let(:tournament) { create(:twilight_struggle_tournament) }
  let(:servers) { [create(:server_configuration, name: "Dev Refuge")] }

  it "posts to the tournament's claim route" do
    expect(html).to include(twilight_struggle_tournament_claim_path(tournament))
  end

  it "offers each server as an option" do
    expect(html).to include("Dev Refuge")
  end

  it "gives the select a definite width, since TomSelect copies w-full onto a wrapper that would otherwise collapse in this flex row" do
    expect(html).to include('<div class="w-56">')
  end

  context "when a server has not synced its name yet" do
    let(:servers) { [create(:server_configuration, name: nil)] }

    it "falls back to the guild id" do
      expect(html).to include(servers.first.discord_id.to_s)
    end
  end

  context "when there is nowhere to claim it to" do
    let(:servers) { [] }

    it "explains that instead of rendering an empty picker" do
      expect(html).to include(I18n.t("components.twilight_struggle.claim_form.no_servers"))
      expect(html).not_to include("<select")
    end
  end
end
