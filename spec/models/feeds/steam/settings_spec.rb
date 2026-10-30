# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Steam::Settings do
  describe "validations" do
    subject(:settings) { subscription.settings.tap { |built| built.assign_attributes(body_length:, languages:) } }

    let(:subscription) { create(:feed_subscription) }
    let(:body_length) { "preview" }
    let(:languages) { %w[de en] }

    it { is_expected.to be_valid }

    context "with an unknown body length" do
      let(:body_length) { "everything" }

      it { is_expected.not_to be_valid }
    end

    context "with a language the detector cannot produce" do
      let(:languages) { %w[de xx] }

      it { is_expected.not_to be_valid }
    end

    context "when the subscription already has settings" do
      subject(:settings) { described_class.new(subscription:) }

      before { subscription.save! }

      it { is_expected.not_to be_valid }
    end
  end

  describe "languages normalization" do
    subject(:settings) { described_class.new(languages: ["de", "", "de", "en"]) }

    it "stores each language once and drops blanks" do
      expect(settings.languages).to eq(%w[de en])
    end
  end

  describe "#accepts_language?" do
    subject(:accepted) { described_class.new(languages:).accepts_language?(language) }

    let(:languages) { %w[de en] }
    let(:language) { "de" }

    context "without a filter" do
      let(:languages) { [] }
      let(:language) { "ru" }

      it { is_expected.to be(true) }
    end

    context "when the language is unknown" do
      let(:language) { nil }

      it { is_expected.to be(true) }
    end

    context "when the language is listed" do
      it { is_expected.to be(true) }
    end

    context "when the language is not listed" do
      let(:language) { "ru" }

      it { is_expected.to be(false) }
    end
  end

  describe "languages check constraint" do
    subject(:save) { settings.save!(validate: false) }

    let(:settings) { create(:feed_subscription).settings.tap { |built| built.languages = Integrations::Language::CODES } }

    it "accepts every code the detector can produce" do
      expect { save }.not_to raise_error
    end
  end

  describe "defaults" do
    subject(:settings) { create(:feed_subscription).settings.reload }

    it "previews the body, pings no role and filters no language" do
      expect(settings).to have_attributes(body_length: "preview", role_id: nil, languages: [])
    end
  end
end
