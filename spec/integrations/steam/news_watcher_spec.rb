# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Steam::NewsWatcher do
  let(:watch) { create(:integration_watch, external_id: "440") }
  let(:client) { instance_double(Integrations::Steam::Client) }
  let(:response) { JSON.parse(Rails.root.join("spec/fixtures/integrations/steam/news_440.json").read) }

  describe ".resolve" do
    subject(:target) { described_class.resolve("https://store.steampowered.com/app/1145360/Hades/", apps:) }

    let(:apps) { instance_double(Integrations::Steam::Apps) }
    let(:app) { Integrations::Steam::App.new(id: 1145360, name: "Hades", type: "game", header_image_url: "https://example.com/h.jpg") }

    before do
      allow(apps).to receive(:find).with(1145360).and_return(app)
    end

    it "looks the parsed app id up and describes it as a target" do
      expect(target).to eq(Integrations::Target.new(external_id: "1145360", name: "Hades", image_url: "https://example.com/h.jpg"))
    end
  end

  describe "#observe" do
    subject(:events) { described_class.new(watch, news: Integrations::Steam::News.new(client:)).observe }

    before do
      allow(client).to receive(:get_json) { |*_args, **_kwargs, &block| block.call(response) }
    end

    it "asks for the watch's app" do
      events

      expect(client).to have_received(:get_json).with(anything, anything, params: hash_including(appid: "440"), status_errors: anything)
    end

    it "classifies by feed type and tags" do
      expect(events.map(&:class)).to eq(
        [
          Integrations::Steam::PatchNotesPublished,
          Integrations::Steam::ArticlePublished,
          Integrations::Steam::ArticlePublished
        ]
      )
    end

    it "fills the envelope and payload from the news item" do
      expect(events.first).to have_attributes(
        watch:,
        subject_key: "1846651706682902",
        occurred_at: Time.zone.at(1792179520),
        title: "Team Fortress 2 Update Released",
        url: "https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1846651706682902",
        author: "erics",
        feed_name: "steam_community_announcements",
        feed_label: "Community Announcements",
        image_urls: []
      )
    end

    it "converts BBCode and HTML bodies to the same Markdown" do
      expect(events.map(&:body).uniq.size).to eq(1)
    end

    it "renders nested lists in the body" do
      expect(events.first.body).to include("- Updated cp_holyhell\n  - Fixed BLU side skybox not rendering for users with HDR enabled")
    end

    it "gives the three mirrors one story key" do
      expect(events.map(&:story_key)).to all(eq("1846651706682901"))
    end

    it "persists nothing" do
      expect { events }.not_to change(Integrations::Event, :count)
    end

    context "with an untagged community post" do
      before do
        response["appnews"]["newsitems"].first.delete("tags")
      end

      it "is an announcement" do
        expect(events.first).to be_a(Integrations::Steam::AnnouncementPublished)
      end
    end

    context "with images in a community post" do
      before do
        response["appnews"]["newsitems"].first["contents"] = "Look [img]{STEAM_CLAN_IMAGE}/44/abc.png[/img]"
      end

      it "lifts them into image_urls with the placeholder expanded" do
        expect(events.first).to have_attributes(
          body: "Look",
          image_urls: ["https://clan.akamai.steamstatic.com/images/44/abc.png"]
        )
      end
    end
  end
end
