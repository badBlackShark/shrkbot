# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Twitch::TitleMatch do
  describe ".names?" do
    subject(:named) { described_class.names?(title, category) }

    let(:title) { "Twilight Struggle" }
    let(:category) { "Twilight Struggle" }

    it { is_expected.to be(true) }

    context "with different case and surrounding words" do
      let(:title) { "ranked TWILIGHT STRUGGLE with chat" }

      it { is_expected.to be(true) }
    end

    context "with accents on one side" do
      let(:title) { "Pokemon Emerald nuzlocke" }
      let(:category) { "Pokémon Emerald" }

      it { is_expected.to be(true) }
    end

    context "with punctuation on one side" do
      let(:title) { "counter strike 2 grind" }
      let(:category) { "Counter-Strike 2" }

      it { is_expected.to be(true) }
    end

    context "with a Roman numeral on one side" do
      let(:title) { "Hades 2 blind run" }
      let(:category) { "Hades II" }

      it { is_expected.to be(true) }
    end

    context "with & on one side" do
      let(:title) { "Dungeons and Dragons night" }
      let(:category) { "Dungeons & Dragons" }

      it { is_expected.to be(true) }
    end

    context "when the category is only part of a word" do
      let(:title) { "Chessboxing night" }
      let(:category) { "Chess" }

      it { is_expected.to be(false) }
    end

    context "when the words are out of order" do
      let(:title) { "Struggle of the Twilight" }

      it { is_expected.to be(false) }
    end

    context "with a misspelt title" do
      let(:title) { "Twilight Strugle" }

      it { is_expected.to be(false) }
    end

    context "with a category in a script that has no Latin letters" do
      let(:title) { "daily run" }
      let(:category) { "原神" }

      it { is_expected.to be(false) }
    end
  end
end
