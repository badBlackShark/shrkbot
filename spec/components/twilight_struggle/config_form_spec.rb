# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::TwilightStruggle::ConfigForm do
  subject(:html) { described_class.new(tournament:, enable_error:).render_in(view_context) }

  let(:view_context) { ApplicationController.new.view_context }
  let(:server_configuration) { create(:server_configuration) }
  let(:tournament) { create(:twilight_struggle_tournament, server_configuration:) }
  let(:enable_error) { nil }

  before do
    create(:server_channel, server_configuration:, discord_id: 4242, name: "results")
  end

  it "renders the three template editors" do
    expect(html).to include("tournament[template_win]")
      .and include("tournament[template_tie]")
      .and include("tournament[template_video]")
  end

  it "pre-fills each template so one detail can be edited without retyping the lot" do
    expect(html).to include(I18n.t("twilight_struggle.default_template.win"))
      .and include(I18n.t("twilight_struggle.default_template.tie"))
      .and include(I18n.t("twilight_struggle.default_template.video"))
  end

  context "when the tournament has its own wording" do
    let(:tournament) { create(:twilight_struggle_tournament, server_configuration:, template_win: "{winning_name} took it") }

    it "puts that in the box instead of the default" do
      expect(html).to include("{winning_name} took it</textarea>")
    end

    it "keeps the default as the placeholder, as the hint you get back by clearing the box" do
      expect(html).to include(%(placeholder="#{I18n.t("twilight_struggle.default_template.win")}"))
    end
  end

  it "renders no enable error by default" do
    expect(html).not_to include("Something went wrong")
  end

  context "with an enable error" do
    let(:enable_error) { "Something went wrong" }

    it "renders it as a callout" do
      expect(html).to include("Something went wrong")
    end
  end

  describe "the channel help" do
    it "explains that no channel means no posts" do
      expect(html).to include("With no channel, nothing is posted")
    end

    context "when a parent tournament already has a channel in the same server" do
      let(:parent) { create(:twilight_struggle_tournament, server_configuration:, discord_channel_id: 4242) }
      let(:tournament) { create(:twilight_struggle_tournament, server_configuration:, parent:) }

      it "names the inherited channel instead" do
        expect(html).to include("inherited from the tournament above").and include("# results")
      end
    end

    context "when the inherited channel lives in a server the user cannot see" do
      let(:parent) { create(:twilight_struggle_tournament, server_configuration: create(:server_configuration), discord_channel_id: 999) }
      let(:tournament) { create(:twilight_struggle_tournament, server_configuration:, parent:) }

      it "falls back to the plain help rather than leaking a channel name" do
        expect(html).to include("With no channel, nothing is posted")
      end
    end
  end

  describe "the preview channel label" do
    context "when the tournament has its own channel" do
      let(:tournament) { create(:twilight_struggle_tournament, server_configuration:, discord_channel_id: 4242) }

      it "shows it above the preview" do
        expect(html).to include("# results")
      end
    end
  end
end
