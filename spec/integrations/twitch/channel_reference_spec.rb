# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::ChannelReference do
  describe ".url" do
    subject(:url) { described_class.url("shroud") }

    it "is the channel's page on Twitch" do
      expect(url).to eq("https://www.twitch.tv/shroud")
    end
  end

  describe ".parse" do
    {
      "bare login" => "shroud",
      "login with @ and capitals" => "@Shroud",
      "URL without scheme" => "twitch.tv/shroud",
      "URL with a sub-page" => "https://www.twitch.tv/shroud/videos",
      "mobile URL" => "m.twitch.tv/shroud",
      "upper-case URL with a query" => "HTTPS://TWITCH.TV/Shroud?x=1"
    }.each do |label, input|
      it "reads a #{label}" do
        expect(described_class.parse(input)).to eq("shroud")
      end
    end

    ["", "a b", "@", "a" * 26, "twitch.tv/#{"a" * 26}", "https://youtube.com/shroud", "twitch.tv/"].each do |input|
      it "rejects #{input.inspect} as InvalidReference" do
        expect { described_class.parse(input) }.to raise_error(Integrations::InvalidReference)
      end
    end
  end
end
