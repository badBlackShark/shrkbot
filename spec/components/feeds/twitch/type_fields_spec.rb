# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::Twitch::TypeFields do
  include_context "component view context"

  subject(:html) { described_class.new(subscription:, event_type:).render_in(view_context) { "MARKER" } }

  let(:subscription) { build(:feed_subscription, :twitch) }
  let(:event_type) { "Integrations::Twitch::StreamStarted" }
  let(:clip_warning) { "Big channels get dozens to hundreds of clips per stream" }

  context "with the live type" do
    it "yields the message fields between the viewer toggle and the end mode" do
      expect(html.index("show_viewers")).to be < html.index("MARKER")
      expect(html.index("MARKER")).to be < html.index("live_end_mode")
    end

    it "renders the live role, the end mode and the viewer toggle, and no clip warning" do
      expect(html).to include('name="subscription[live_role_id]"', 'name="subscription[live_end_mode]"', 'name="subscription[show_viewers]"')
      expect(html).not_to include(clip_warning)
    end
  end

  context "with the highlight type" do
    let(:event_type) { "Integrations::Twitch::HighlightPublished" }

    it "yields the message fields and shows neither warning nor window note" do
      expect(html).to include("MARKER")
      expect(html).not_to include(clip_warning, "48 hours")
    end
  end

  context "with all clips" do
    let(:event_type) { "Integrations::Twitch::ClipCreated" }

    it "warns about volume and offers that type's role only" do
      expect(html).to include(clip_warning, 'name="subscription[clips_role_id]"')
      expect(html).not_to include("live_end_mode", "show_viewers")
    end
  end

  context "with featured clips" do
    let(:event_type) { "Integrations::Twitch::FeaturedClipPublished" }

    it "offers its role without the clip warning" do
      expect(html).to include('name="subscription[featured_clips_role_id]"')
      expect(html).not_to include(clip_warning)
    end

    it "explains the 48-hour window" do
      expect(html).to include("Only clips featured within 48 hours of being made get posted.")
    end
  end
end
