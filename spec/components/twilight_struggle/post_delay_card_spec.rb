# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::TwilightStruggle::PostDelayCard do
  subject(:html) { described_class.new(destination:, inherited:).render_in(view_context) }

  let(:view_context) { ApplicationController.new.view_context }
  let(:server_configuration) { create(:server_configuration) }
  let(:tournament) { create(:twilight_struggle_tournament) }
  let(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:) }
  let(:inherited) { TwilightStruggle::EffectiveConfig.new(tournament.parent, server_configuration) }

  it "renders the delay input" do
    expect(html).to include('name="destination[post_delay_minutes]"')
  end

  context "when the destination has its own delay" do
    let(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:, post_delay_seconds: 900) }

    it "shows it in minutes" do
      expect(html).to include('value="15"')
    end
  end

  context "when the destination sets no delay" do
    it "leaves the field empty so it inherits" do
      expect(html).not_to include(" value=")
    end
  end

  context "when the tournament has no parent" do
    it "does not claim anything is inherited" do
      expect(html).not_to include("is set to")
    end
  end

  context "when the tournament hangs under a parent this server also subscribes to" do
    let(:parent) { create(:twilight_struggle_tournament, name: "OTSL 2026") }
    let(:tournament) { create(:twilight_struggle_tournament, parent:) }
    let!(:parent_destination) { create(:twilight_struggle_destination, tournament: parent, server_configuration:, post_delay_seconds: 1800) }

    it "names the parent and its delay in minutes" do
      expect(html).to include("OTSL 2026 is set to 30 minutes.")
    end

    it "uses the inherited minutes as the placeholder" do
      expect(html).to include('placeholder="30"')
    end

    context "when the parent's delay is one minute" do
      let!(:parent_destination) { create(:twilight_struggle_destination, tournament: parent, server_configuration:, post_delay_seconds: 60) }

      it "uses the singular" do
        expect(html).to include("OTSL 2026 is set to 1 minute.")
      end
    end
  end

  context "when the parent subscribes but sets nothing and the grandparent sets it" do
    let(:grandparent) { create(:twilight_struggle_tournament, name: "OTSL") }
    let(:parent) { create(:twilight_struggle_tournament, name: "OTSL 2026", parent: grandparent) }
    let(:tournament) { create(:twilight_struggle_tournament, parent:) }

    before do
      create(:twilight_struggle_destination, tournament: parent, server_configuration:)
      create(:twilight_struggle_destination, tournament: grandparent, server_configuration:, post_delay_seconds: 1800)
    end

    it "names the grandparent that sets it" do
      expect(html).to include("OTSL is set to 30 minutes.")
    end
  end

  context "when no tournament above sets it" do
    let(:parent) { create(:twilight_struggle_tournament, name: "OTSL 2026") }
    let(:tournament) { create(:twilight_struggle_tournament, parent:) }

    before { create(:twilight_struggle_destination, tournament: parent, server_configuration:) }

    it "says where the value comes from instead" do
      expect(html).to include("No tournament above sets a delay, so results post immediately.")
    end
  end
end
