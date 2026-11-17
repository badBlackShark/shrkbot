# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Twitch::Settings do
  subject(:settings) { subscription.settings }

  let(:subscription) { create(:feed_subscription, :twitch) }

  it "shows viewers by default" do
    expect(settings.show_viewers).to be(true)
  end

  it "shows the preview frame by default" do
    expect(settings.show_preview_frame).to be(true)
  end

  it "shows every thumbnail by default" do
    expect(settings).to have_attributes(
      show_highlights_thumbnail: true,
      show_uploads_thumbnail: true,
      show_featured_clips_thumbnail: true,
      show_clips_thumbnail: true
    )
  end

  describe "#show_image?" do
    subject(:shown) { settings.show_image?(event_type) }

    let(:event_type) { "Integrations::Twitch::ClipCreated" }

    it "follows the type's own column" do
      expect(shown).to be(true)
    end

    context "when the clip thumbnail is off" do
      before do
        settings.show_clips_thumbnail = false
      end

      it "is false for clips only" do
        expect(shown).to be(false)
        expect(settings.show_image?("Integrations::Twitch::HighlightPublished")).to be(true)
      end
    end
  end

  it "marks the card ended with a VOD link by default" do
    expect(settings.live_end_mode).to eq("mark_ended_with_vod")
  end

  describe "live_end_mode" do
    before { settings.live_end_mode = "vanish" }

    it { is_expected.not_to be_valid }
  end

  it "summarises a stream that switched away by default" do
    expect(settings.switched_away).to eq("summary")
  end

  describe "switched_away" do
    before { settings.switched_away = "vanish" }

    it { is_expected.not_to be_valid }
  end

  describe "categories" do
    before { settings.categories = categories }

    context "with a well-formed entry" do
      let(:categories) { [{"id" => "A", "name" => "Alpha"}] }

      it { is_expected.to be_valid }
    end

    context "with a non-hash entry" do
      let(:categories) { ["A"] }

      it { is_expected.not_to be_valid }
    end

    context "with an entry without an id" do
      let(:categories) { [{"name" => "Alpha"}] }

      it { is_expected.not_to be_valid }
    end

    context "with exactly the maximum number of entries" do
      let(:categories) { Array.new(described_class::MAX_CATEGORIES) { |index| {"id" => index.to_s, "name" => "Game #{index}"} } }

      it { is_expected.to be_valid }
    end

    context "with more than the maximum number of entries" do
      let(:categories) { Array.new(described_class::MAX_CATEGORIES + 1) { |index| {"id" => index.to_s, "name" => "Game #{index}"} } }

      it "is invalid and says how many are allowed" do
        settings.validate

        expect(settings.errors[:categories]).to eq(["can have at most 100 categories"])
      end
    end
  end

  describe "#accepts_category?" do
    subject(:accepted) { settings.accepts_category?(category_id) }

    let(:category_id) { "A" }

    before { settings.categories = categories }

    context "when no category is listed" do
      let(:categories) { [] }

      it { is_expected.to be(true) }

      context "with an unknown category" do
        let(:category_id) { nil }

        it { is_expected.to be(true) }
      end
    end

    context "when categories are listed" do
      let(:categories) { [{"id" => "A", "name" => "Alpha"}] }

      it { is_expected.to be(true) }

      context "with another category" do
        let(:category_id) { "B" }

        it { is_expected.to be(false) }
      end

      context "with an unknown category" do
        let(:category_id) { nil }

        it { is_expected.to be(false) }
      end
    end
  end

  describe "#role_id_for" do
    subject(:role_id) { settings.role_id_for(event_type) }

    before { settings.update!(role_id: 5, live_role_id: 77, featured_clips_role_id: 88) }

    context "with a live event" do
      let(:event_type) { "Integrations::Twitch::StreamStarted" }

      it { is_expected.to eq(77) }
    end

    context "with a media event" do
      let(:event_type) { "Integrations::Twitch::FeaturedClipPublished" }

      it { is_expected.to eq(88) }
    end

    context "with a type without an override" do
      let(:event_type) { "Integrations::Twitch::UploadPublished" }

      it { is_expected.to eq(5) }
    end

    context "with an unknown event type" do
      let(:event_type) { "Integrations::Twitch::Nonsense" }

      it "raises" do
        expect { role_id }.to raise_error(KeyError)
      end
    end

    context "with a no-ping override on a type while the follow has a role" do
      let(:event_type) { "Integrations::Twitch::StreamStarted" }

      before { settings.update!(live_role_id: Feeds::Twitch::Settings::NO_PING) }

      it { is_expected.to be_nil }
    end
  end

  describe "#role_override_for" do
    subject(:override) { settings.role_override_for("Integrations::Twitch::UploadPublished") }

    before { settings.update!(role_id: 5) }

    it "ignores the follow's role" do
      expect(override).to be_nil
    end
  end

  describe "uniqueness" do
    subject(:duplicate) { described_class.new(subscription:) }

    it { is_expected.not_to be_valid }
  end
end
