# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::SubscriptionRow do
  include_context "component view context"

  subject(:document) do
    html = described_class.new(subscription:, plugin_key:, channel_label: "#clips", role_names:).render_in(view_context)
    Nokogiri::HTML5.fragment(html)
  end

  let(:plugin_key) { :twitch }
  let(:role_names) { {1 => "Streams"} }
  let(:failing_since) { 25.hours.ago }
  let(:watch) { create(:integration_watch, :twitch, failing_since:) }
  let(:subscription) { create(:feed_subscription, :twitch, watch:) }
  let(:text) { document.text.squish }
  let(:badges) { document.css("span").map { |badge| badge.text.squish } }

  it "says Twitch has not answered for the channel's videos and clips, and that live posts still work" do
    expect(text).to include(
      "Twitch hasn't answered for this channel's videos and clips since",
      "UTC; live posts still work."
    )
  end

  context "when every followed type pings the same role" do
    let(:plugin_key) { :steam }
    let(:role_names) { {7 => "Updates"} }
    let(:watch) { create(:integration_watch) }
    let(:subscription) do
      build(:steam_feed_subscription, role_id: 7, watch:).tap do |built|
        built.follow("Integrations::Steam::PatchNotesPublished")
        built.follow("Integrations::Steam::AnnouncementPublished")
        built.save!
      end
    end

    it "shows the role in the meta line" do
      expect(text).to include("#clips - pings @Updates")
    end

    it "leaves the badges plain" do
      expect(text).to include("Patch notes").and include("Announcements")
      expect(text).not_to include("Patch notes · @")
    end
  end

  context "when followed types ping different roles" do
    let(:role_names) { {1 => "Streams", 2 => "Clips"} }

    before do
      subscription.settings.update!(live_role_id: 1, highlights_role_id: 2)
      subscription.follow("Integrations::Twitch::StreamStarted")
      subscription.follow("Integrations::Twitch::HighlightPublished")
      subscription.save!
    end

    it "names each role on its badge" do
      expect(text).to include("Live · @Streams").and include("Highlights · @Clips")
    end

    it "drops the shared ping from the meta line" do
      expect(text).not_to include("pings")
    end

    context "when one of them pings no role" do
      let(:role_names) { {1 => "Streams"} }

      before do
        subscription.settings.update!(highlights_role_id: nil)
      end

      it "leaves that badge plain" do
        expect(badges).to include("Live · @Streams", "Highlights")
      end
    end

    context "when one of the roles was deleted" do
      let(:role_names) { {1 => "Streams"} }

      it "says so on that badge" do
        expect(badges).to include("Highlights · a role that was deleted")
      end
    end
  end
end
