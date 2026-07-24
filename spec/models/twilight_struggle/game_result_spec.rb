# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwilightStruggle::GameResult do
  subject(:result) { described_class.new(attributes) }

  let(:attributes) do
    {
      usa_player: "Alice",
      ussr_player: "Bob",
      winning_side: "usa",
      winning_method: "Coup",
      winning_turn: 7,
      reported_at: Time.current,
      video_urls: []
    }
  end

  it "is valid with a full payload" do
    expect(result).to be_valid
  end

  describe "winning_side" do
    it "is invalid with an unknown side" do
      attributes[:winning_side] = "china"
      expect(result).not_to be_valid
    end
  end

  describe "winning_turn" do
    it "is invalid below the minimum turn" do
      attributes[:winning_turn] = 0
      expect(result).not_to be_valid
    end

    it "is invalid above the maximum turn" do
      attributes[:winning_turn] = 12
      expect(result).not_to be_valid
    end
  end

  describe "usa_player" do
    it "is invalid when missing" do
      attributes[:usa_player] = nil
      expect(result).not_to be_valid
    end

    it "is invalid over the name limit" do
      attributes[:usa_player] = "a" * (described_class::NAME_LIMIT + 1)
      expect(result).not_to be_valid
    end
  end

  describe "winning_method" do
    it "is invalid over the method limit" do
      attributes[:winning_method] = "a" * (described_class::METHOD_LIMIT + 1)
      expect(result).not_to be_valid
    end
  end

  describe "reported_at" do
    it "is invalid when missing" do
      attributes[:reported_at] = nil
      expect(result).not_to be_valid
    end
  end

  describe "video_urls" do
    it "accepts an https url" do
      attributes[:video_urls] = ["https://example.com/clip"]
      expect(result).to be_valid
    end

    it "accepts an http url" do
      attributes[:video_urls] = ["http://example.com/clip"]
      expect(result).to be_valid
    end

    it "rejects a javascript url" do
      attributes[:video_urls] = ["javascript:alert(1)"]
      expect(result).not_to be_valid
    end

    it "rejects a non-uri string" do
      attributes[:video_urls] = ["not a url at all"]
      expect(result).not_to be_valid
    end

    it "rejects more than five urls" do
      attributes[:video_urls] = Array.new(6) { |n| "https://example.com/#{n}" }
      expect(result).not_to be_valid
    end

    it "accepts an empty array" do
      attributes[:video_urls] = []
      expect(result).to be_valid
    end
  end
end
