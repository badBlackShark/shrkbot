# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Steam::PreviewSamples do
  subject(:samples) { described_class.new(watch_name: "Hades II", event_type: "Integrations::Steam::ArticlePublished") }

  describe "#value" do
    it "is the watch name for game" do
      expect(samples.value("game")).to eq("Hades II")
    end

    it "reads the sample copy for every other name" do
      expect(samples.value("feed")).to eq("PC Gamer")
      expect(samples.value(:title)).to eq("Our review of the 1.0 release")
    end
  end

  describe "#tokens" do
    it "maps each name to its sample" do
      expect(samples.tokens(%w[game author feed])).to eq("game" => "Hades II", "author" => "Jane Doe", "feed" => "PC Gamer")
    end
  end
end
