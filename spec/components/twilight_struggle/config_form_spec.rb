# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::TwilightStruggle::ConfigForm do
  subject(:html) { described_class.new(destination:).render_in(view_context) }

  let(:view_context) { ApplicationController.new.view_context }
  let(:server_configuration) { create(:server_configuration) }
  let(:tournament) { create(:twilight_struggle_tournament) }
  let(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:) }

  before do
    create(:server_channel, server_configuration:, discord_id: 4200, name: "Tournaments", channel_type: ServerChannel::CATEGORY_TYPE)
    create(:server_channel, server_configuration:, discord_id: 4242, name: "results", parent_id: 4200)
  end

  it "renders the three template editors" do
    expect(html).to include("destination[template_win]")
      .and include("destination[template_tie]")
      .and include("destination[template_video]")
  end

  it "pre-fills each template so one detail can be edited without retyping the lot" do
    expect(html).to include(I18n.t("twilight_struggle.default_template.win"))
      .and include(I18n.t("twilight_struggle.default_template.tie"))
      .and include(I18n.t("twilight_struggle.default_template.video"))
  end

  context "when the destination has its own wording" do
    let(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:, template_win: "{winning_name} took it") }

    it "puts that in the box instead of the default" do
      expect(html).to include("{winning_name} took it</textarea>")
    end

    it "keeps the default as the placeholder, as the hint you get back by clearing the box" do
      expect(html).to include(%(placeholder="#{I18n.t("twilight_struggle.default_template.win")}"))
    end
  end

  describe "the channel help" do
    it "explains that no channel means no posts" do
      expect(html).to include("With no channel, nothing is posted")
    end

    context "when this server's destination for a parent tournament already has a channel" do
      let(:parent) { create(:twilight_struggle_tournament) }
      let(:tournament) { create(:twilight_struggle_tournament, parent:) }
      let!(:parent_destination) { create(:twilight_struggle_destination, tournament: parent, server_configuration:, discord_channel_id: 4242) }

      it "names the inherited channel instead" do
        expect(html).to include("inherited from the tournament above").and include("Tournaments / #results")
      end
    end

    context "when the inherited channel lives in a server the user cannot see" do
      let(:parent) { create(:twilight_struggle_tournament) }
      let(:tournament) { create(:twilight_struggle_tournament, parent:) }
      let!(:parent_destination) { create(:twilight_struggle_destination, tournament: parent, server_configuration: create(:server_configuration), discord_channel_id: 999) }

      it "falls back to the plain help rather than leaking a channel name" do
        expect(html).to include("With no channel, nothing is posted")
      end
    end
  end

  describe "the preview channel label" do
    context "when the destination has its own channel" do
      let(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:, discord_channel_id: 4242) }

      it "shows it above the preview, as Discord names it" do
        expect(html).to include("#results")
      end
    end
  end
end
