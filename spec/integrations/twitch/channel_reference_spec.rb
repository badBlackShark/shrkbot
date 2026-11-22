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
    JSON.parse(Rails.root.join("spec/fixtures/channel_references.json").read).each do |reference|
      it "reads #{reference["input"].inspect} as #{reference["login"]}" do
        expect(described_class.parse(reference["input"])).to eq(reference["login"])
      end
    end

    ["", "a b", "@", "a" * 26, "twitch.tv/#{"a" * 26}", "https://youtube.com/shroud", "twitch.tv/"].each do |input|
      it "rejects #{input.inspect} as InvalidReference" do
        expect { described_class.parse(input) }.to raise_error(Integrations::InvalidReference)
      end
    end
  end
end
