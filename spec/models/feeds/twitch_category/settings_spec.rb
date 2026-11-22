# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::TwitchCategory::Settings do
  subject(:settings) { subscription.settings }

  let(:subscription) { create(:feed_subscription, :twitch_category) }

  it "starts with no floor and no filters" do
    expect(settings).to have_attributes(min_viewers: 0, languages: [], excluded_channels: [], show_viewers: true, show_preview_frame: true)
  end

  describe "validations" do
    it "refuses a negative floor" do
      settings.min_viewers = -1

      expect(settings).not_to be_valid
    end

    it "refuses a fractional floor" do
      settings.min_viewers = 1.5

      expect(settings).not_to be_valid
    end

    it "refuses an unknown live end mode" do
      settings.live_end_mode = "vanish"

      expect(settings).not_to be_valid
    end

    it "refuses an unknown switched-away mode" do
      settings.switched_away = "vanish"

      expect(settings).not_to be_valid
    end

    it "takes a language code, a regional code and other" do
      settings.languages = %w[en pt-br other]

      expect(settings).to be_valid
    end

    it "takes every language the picker offers" do
      settings.languages = Feeds::TwitchCategory::LANGUAGES

      expect(settings).to be_valid
    end

    it "refuses text that is not a language code" do
      settings.languages = ["English"]

      expect(settings).not_to be_valid
    end

    it "refuses more languages than the cap" do
      settings.languages = Array.new(described_class::MAX_LANGUAGES + 1, "en")

      expect(settings).not_to be_valid
    end

    it "refuses more excluded channels than the cap" do
      settings.excluded_channels = Array.new(described_class::MAX_EXCLUDED + 1) { |index| "channel_#{index}" }

      expect(settings).not_to be_valid
    end

    it "refuses an excluded name that is not a Twitch login" do
      settings.excluded_channels = ["not a login!"]

      expect(settings).not_to be_valid
    end
  end

  describe "#excluded_channels=" do
    it "reduces handles and links to lowercase logins, once each" do
      settings.excluded_channels = ["@Name", "https://twitch.tv/Name/", " other ", ""]

      expect(settings.excluded_channels).to eq(%w[name other])
    end
  end

  describe "#accepts_stream?" do
    subject(:accepted) { settings.accepts_stream?(event) }

    let(:event) { build(:twitch_stream_started_event, login: "Streamer", language: "de") }

    it { is_expected.to be(true) }

    context "with a language filter that includes the stream's" do
      before { settings.languages = %w[en de] }

      it { is_expected.to be(true) }
    end

    context "with a language filter that leaves it out" do
      before { settings.languages = %w[en] }

      it { is_expected.to be(false) }
    end

    context "with a language filter and a stream of unknown language" do
      let(:event) { build(:twitch_stream_started_event, login: "streamer", language: nil) }

      before { settings.languages = %w[en] }

      it { is_expected.to be(false) }
    end

    context "when the streamer is excluded" do
      before { settings.excluded_channels = ["@streamer"] }

      it { is_expected.to be(false) }
    end
  end

  describe "#meets_floor?" do
    subject(:met) { settings.meets_floor?(event) }

    let(:event) { build(:twitch_stream_sampled_event, viewer_count:) }
    let(:viewer_count) { 50 }

    before { settings.min_viewers = 50 }

    it { is_expected.to be(true) }

    context "when one viewer short" do
      let(:viewer_count) { 49 }

      it { is_expected.to be(false) }
    end

    context "when the event carries no count" do
      let(:viewer_count) { nil }

      it { is_expected.to be(false) }
    end
  end

  describe "#show_image?" do
    it "follows the preview frame toggle" do
      settings.show_preview_frame = false

      expect(settings.show_image?("Integrations::Twitch::StreamStarted")).to be(false)
    end
  end
end
