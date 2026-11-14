# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::TwilightStruggle::ConfigForm do
  subject(:html) { described_class.new(destination:).render_in(view_context) }

  let(:view_context) { ApplicationController.new.view_context }
  let(:server_configuration) { create(:server_configuration) }
  let(:tournament) { create(:twilight_struggle_tournament) }
  let(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:) }
  let(:fragment) { Nokogiri::HTML5.fragment(html) }

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
  end

  context "when the destination posts nothing for decided games" do
    let(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:, template_win: "") }

    it "leaves that box empty instead of pre-filling it" do
      expect(fragment.at_css("textarea[name='destination[template_win]']").text).to eq("")
    end

    it "offers the reset" do
      expect(fragment.at_css("[data-twilight-struggle-preview-target=winReset]").key?("hidden")).to be(false)
    end
  end

  describe "an emptied box" do
    it "says nothing will be sent" do
      placeholders = fragment.css("textarea[name^='destination[template_']").map { |box| box["placeholder"] }
      expect(placeholders).to eq(["Nothing will be sent."] * 3)
    end
  end

  describe "the reset button" do
    it "brings back the inherited text" do
      box = fragment.at_css("textarea[name='destination[template_win]']")
      button = fragment.at_css("[data-twilight-struggle-preview-target=winReset] button")
      expect(box["data-default"]).to eq(I18n.t("twilight_struggle.default_template.win"))
      expect(button["data-twilight-struggle-preview-kind-param"]).to eq("win")
    end

    it "hides while each box holds what it inherits" do
      resets = %w[winReset tieReset videoReset].map { |target| fragment.at_css("[data-twilight-struggle-preview-target=#{target}]") }
      expect(resets.map { |reset| reset.key?("hidden") }).to eq([true, true, true])
    end

    context "when the destination has its own wording" do
      let(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:, template_win: "{winning_name} took it") }

      it "shows only that template's reset" do
        expect(fragment.at_css("[data-twilight-struggle-preview-target=winReset]").key?("hidden")).to be(false)
        expect(fragment.at_css("[data-twilight-struggle-preview-target=tieReset]").key?("hidden")).to be(true)
      end
    end

    it "offers resetting each template back to the default" do
      expect(html.scan(I18n.t("components.twilight_struggle.template_card.reset_to_default")).size).to eq(6)
    end

    context "when a parent tournament this server also subscribes to supplies the wording" do
      let(:parent) { create(:twilight_struggle_tournament) }
      let(:tournament) { create(:twilight_struggle_tournament, parent:) }
      let!(:parent_destination) { create(:twilight_struggle_destination, tournament: parent, server_configuration:) }

      it "calls it resetting to the parent instead" do
        expect(html).to include(I18n.t("components.twilight_struggle.template_card.reset_to_parent"))
        expect(html).not_to include(I18n.t("components.twilight_struggle.template_card.reset_to_default"))
      end
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
