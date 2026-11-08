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
      expect(samples.card).to eq(
        eyebrow: "Hades II · PC Gamer",
        title: "Our review of the 1.0 release",
        body: "A first look at the full release.",
        button: Feeds::Steam::Announcement::LINK_LABEL
      )
    end
  end
end
