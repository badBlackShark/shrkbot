# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Steam::PreviewSamples do
  subject(:samples) { described_class.new(watch_name: "Hades II", event_type: "Integrations::Steam::ArticlePublished") }

  describe "#tokens" do
    it "maps the watch name for game and the sample copy for every other name" do
      expect(samples.tokens(%w[game author feed title])).to eq(
        "game" => "Hades II",
        "author" => "Jane Doe",
        "feed" => "PC Gamer",
        "title" => "Our review of the 1.0 release"
      )
    end
  end

  describe "#card" do
    it "words the card like the steam announcement" do
      expect(samples.card).to include(
        eyebrow: "Hades II · PC Gamer",
        title: "Our review of the 1.0 release",
        body: "A first look at the full release.",
        button: Feeds::Steam::Announcement::LINK_LABEL
      )
    end

    %w[PatchNotesPublished AnnouncementPublished ArticlePublished].each do |type|
      context "with #{type}" do
        subject(:samples) { described_class.new(watch_name: "Hades II", event_type: "Integrations::Steam::#{type}") }

        it "shows the game artwork beside the heading and the first post image below, as a real post does" do
          expect(samples.card).to include(thumbnail: "Game artwork", media: {label: "First image in the post"})
        end

        it "has no footer" do
          expect(samples.card).not_to have_key(:footer)
        end
      end
    end
  end
end
