# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::Twitch::TypeFields do
  include_context "component view context"

  subject(:html) { described_class.new(subscription:, event_type:, event: nil).render_in(view_context) { "MARKER" } }

  let(:subscription) { build(:feed_subscription, :twitch) }
  let(:event_type) { "Integrations::Twitch::StreamStarted" }
  let(:document) { Nokogiri::HTML.fragment(html) }

  context "with the live type" do
    it "yields the message fields between the viewer toggle and the end mode" do
      expect(html.index("show_viewers")).to be < html.index("MARKER")
      expect(html.index("MARKER")).to be < html.index("live_end_mode")
    end

    it "renders the live role, the end mode and the viewer toggle" do
      expect(html).to include('name="subscription[live_role_id]"', 'name="subscription[live_end_mode]"', 'name="subscription[show_viewers]"', 'name="subscription[show_preview_frame]"')
    end

    it "labels the preview frame toggle" do
      expect(document.text).to include("Show a preview frame", "Show the viewer count")
    end

    it "puts the role override beside the channel override" do
      row = document.at_css("div.flex-wrap")

      expect(row.css("select").map { |select| select["name"] }).to eq(
        ["subscription[choices][#{event_type}][channel_id]", "subscription[live_role_id]"]
      )
      expect(row.text).to include("Role override")
      expect(row.to_html).to include("Same as above")
    end

    context "when only the follow has a role" do
      before do
        create(:server_role, server_configuration: subscription.server_configuration, discord_id: 1)
        subscription.settings.role_id = 1
      end

      it "leaves the override empty" do
        expect(document.at_css("select[name='subscription[live_role_id]'] option[selected]")).to be_nil
      end
    end
  end

  context "with the no-ping option" do
    it "is on the role override and not on the follow's own role" do
      expect(document.css("select[name='subscription[live_role_id]'] option[value='0']").map(&:text)).to eq(["No ping"])
    end
  end

  context "with all clips" do
    let(:event_type) { "Integrations::Twitch::ClipCreated" }

    it "offers that type's role only" do
      expect(html).to include('name="subscription[clips_role_id]"')
      expect(html).not_to include("live_end_mode", "show_viewers", "show_preview_frame")
    end

    it "offers its thumbnail toggle" do
      expect(html).to include('name="subscription[show_clips_thumbnail]"')
    end
  end

  context "with a highlight" do
    let(:event_type) { "Integrations::Twitch::HighlightPublished" }

    it "offers the thumbnail toggle and no viewer toggle" do
      expect(html).to include('name="subscription[show_highlights_thumbnail]"')
      expect(document.text).to include("Show the thumbnail")
      expect(html).not_to include("show_viewers")
    end
  end

  context "with featured clips" do
    let(:event_type) { "Integrations::Twitch::FeaturedClipPublished" }

    it "offers its role" do
      expect(html).to include('name="subscription[featured_clips_role_id]"')
    end
  end
end
