# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::TwilightStruggle::PingCard do
  subject(:html) { described_class.new(tournament:, inherited:).render_in(view_context) }

  let(:view_context) { ApplicationController.new.view_context }
  let(:tournament) { create(:twilight_struggle_tournament) }
  let(:inherited) { TwilightStruggle::EffectiveConfig.new(tournament.parent) }

  it "offers all three states" do
    expect(html).to include("Inherit").and include("Mention").and include("Names")
  end

  context "when the tournament sets no preference" do
    it "leaves the control on inherit" do
      expect(html).to include('value="" data-segmented-target="input"')
    end

    it "spells out what inherit currently resolves to" do
      expect(html).to include("Inherited setting: Names.")
    end
  end

  context "when the tournament mentions players" do
    let(:tournament) { create(:twilight_struggle_tournament, ping_players: true) }

    it "selects mention" do
      expect(html).to include('value="1" data-segmented-target="input"')
    end
  end

  context "when the tournament uses names" do
    let(:tournament) { create(:twilight_struggle_tournament, ping_players: false) }

    it "selects names" do
      expect(html).to include('value="0" data-segmented-target="input"')
    end
  end

  context "when a parent tournament mentions players" do
    let(:parent) { create(:twilight_struggle_tournament, ping_players: true) }
    let(:tournament) { create(:twilight_struggle_tournament, parent:) }

    it "says inherit resolves to mention" do
      expect(html).to include("Inherited setting: Mention.")
    end
  end
end
