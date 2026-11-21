# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwilightStruggle::CountryFlag do
  describe ".for" do
    subject { described_class.for(country_code) }

    context "with a country code the table knows" do
      let(:country_code) { "de" }

      it { is_expected.to eq("🇩🇪") }
    end

    context "with the code in upper case, as the site spells it" do
      let(:country_code) { "DE" }

      it { is_expected.to eq("🇩🇪") }
    end

    context "with a code whose letters are not its flag" do
      let(:country_code) { "UK" }

      it { is_expected.to eq("🇬🇧") }
    end

    context "with a region that has no two-letter code" do
      let(:country_code) { "SCOT" }

      it { is_expected.to eq("🏴󠁧󠁢󠁳󠁣󠁴󠁿") }
    end

    context "with a code YAML would otherwise read as a boolean" do
      let(:country_code) { "no" }

      it { is_expected.to eq("🇳🇴") }
    end

    context "with a region Unicode has no flag for" do
      let(:country_code) { "CAT" }

      before { allow(Bot::Discord::ApplicationEmoji).to receive(:mention).with("catalonia").and_return("<:catalonia:42>") }

      it { is_expected.to eq("<:catalonia:42>") }
    end

    context "with a region whose emoji this bot has not uploaded yet" do
      let(:country_code) { "CAT" }

      before { allow(Bot::Discord::ApplicationEmoji).to receive(:mention).and_return(nil) }

      it { is_expected.to be_nil }
    end

    context "with a code the table does not cover" do
      let(:country_code) { "ZZ" }

      it { is_expected.to be_nil }
    end

    context "without a country code" do
      let(:country_code) { nil }

      it { is_expected.to be_nil }
    end

    context "with a blank country code" do
      let(:country_code) { "  " }

      it { is_expected.to be_nil }
    end
  end
end
