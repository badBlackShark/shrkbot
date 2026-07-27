# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::TwilightStruggle::PingCard do
  subject(:html) { described_class.new(destination:, inherited:).render_in(view_context) }

  let(:view_context) { ApplicationController.new.view_context }
  let(:server_configuration) { create(:server_configuration) }
  let(:tournament) { create(:twilight_struggle_tournament) }
  let(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:) }
  let(:inherited) { TwilightStruggle::EffectiveConfig.new(tournament.parent, server_configuration) }

  context "when the tournament has no parent" do
    it "offers only the two real choices, since there is nothing to inherit from" do
      expect(html).to include("Name and tag").and include("Name only")
      expect(html).not_to include("Inherit")
    end

    it "defaults to name only" do
      expect(html).to include('value="0" data-segmented-target="input"')
    end

    it "does not claim anything is inherited" do
      expect(html).not_to include("is set to")
    end

    context "when tags are switched on" do
      let(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:, ping_players: true) }

      it "selects name and tag" do
        expect(html).to include('value="1" data-segmented-target="input"')
      end
    end
  end

  context "when the tournament hangs under a parent this server also subscribes to" do
    let(:parent) { create(:twilight_struggle_tournament, name: "OTSL 2026") }
    let(:tournament) { create(:twilight_struggle_tournament, parent:) }
    let!(:parent_destination) { create(:twilight_struggle_destination, tournament: parent, server_configuration:, ping_players: true) }

    it "offers inherit as well" do
      expect(html).to include("Inherit")
    end

    it "starts on inherit while the destination sets nothing" do
      expect(html).to include('value="" data-segmented-target="input"')
    end

    it "names the parent and what it resolves to" do
      expect(html).to include("OTSL 2026 is set to Name and tag.")
    end

    context "when the destination overrides the parent" do
      let(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:, ping_players: false) }

      it "selects the override" do
        expect(html).to include('value="0" data-segmented-target="input"')
      end

      it "still names what inherit would give" do
        expect(html).to include("OTSL 2026 is set to Name and tag.")
      end
    end
  end

  context "when the tournament has a parent but this server has no destination for it" do
    let(:parent) { create(:twilight_struggle_tournament, name: "OTSL 2026") }
    let(:tournament) { create(:twilight_struggle_tournament, parent:) }

    it "offers only the two real choices, since this server has nothing to inherit from" do
      expect(html).not_to include("Inherit")
    end
  end
end
