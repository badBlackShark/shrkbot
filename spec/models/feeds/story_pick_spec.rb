# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::StoryPick do
  subject(:pick) { described_class.new(subscription:, event:) }

  let(:subscription) { create(:feed_subscription) }
  let(:watch) { subscription.watch }
  let(:subscribed_types) { %w[Integrations::Steam::PatchNotesPublished Integrations::Steam::ArticlePublished] }
  let(:subscribed_since) { 1.day.ago }
  let!(:patch_notes) { create(:steam_news_event, watch:, story_key: "story-1", occurred_at: 2.hours.ago) }
  let!(:article) { create(:steam_article_event, watch:, story_key: "story-1", occurred_at: 3.hours.ago) }
  let!(:other_story) { create(:steam_news_event, watch:, story_key: "story-2", occurred_at: 5.hours.ago) }
  let(:event) { patch_notes }

  before do
    subscribed_types.each do |event_type|
      create(:feed_subscribed_event, subscription:, event_type:, subscribed_since:)
    end
  end

  context "when a non-article copy and an older article copy are both subscribed" do
    it "prefers the non-article copy for the non-article event" do
      expect(pick).to be_best
    end

    context "when asked about the article copy" do
      let(:event) { article }

      it "defers to the non-article copy even though the article is older" do
        expect(pick).not_to be_best
      end
    end
  end

  context "when the subscription follows articles only" do
    let(:subscribed_types) { %w[Integrations::Steam::ArticlePublished] }
    let(:event) { article }

    it "picks the article" do
      expect(pick).to be_best
    end
  end

  context "when two non-article copies are subscribed" do
    let!(:announcement) do
      create(:steam_announcement_event, watch:, story_key: "story-1", occurred_at: 4.hours.ago)
    end
    let(:subscribed_types) { %w[Integrations::Steam::PatchNotesPublished Integrations::Steam::AnnouncementPublished] }

    context "when asked about the earlier one" do
      let(:event) { announcement }

      it "prefers the earliest occurrence" do
        expect(pick).to be_best
      end
    end

    context "when asked about the later one" do
      it "defers to the earlier one" do
        expect(pick).not_to be_best
      end
    end
  end

  context "when copies tie on occurrence time" do
    let!(:twin) { create(:steam_news_event, watch:, story_key: "story-1", occurred_at: patch_notes.occurred_at) }
    let(:winner) { [patch_notes, twin].min_by(&:id) }

    context "when asked about the lowest id" do
      let(:event) { winner }

      it "is the best" do
        expect(pick).to be_best
      end
    end

    context "when asked about the other one" do
      let(:event) { ([patch_notes, twin] - [winner]).first }

      it "defers to the lowest id" do
        expect(pick).not_to be_best
      end
    end
  end

  context "when the better copy's type is not subscribed" do
    let(:subscribed_types) { %w[Integrations::Steam::ArticlePublished] }
    let(:event) { article }

    it "ignores it" do
      expect(pick).to be_best
    end
  end

  context "when the same story key exists on another watch" do
    let!(:foreign) { create(:steam_news_event, story_key: "story-1", occurred_at: 10.hours.ago) }

    it "ignores it" do
      expect(pick).to be_best
    end
  end

  context "when the event's own type is not subscribed" do
    let(:subscribed_types) { %w[Integrations::Steam::ArticlePublished] }

    it "is never the best" do
      expect(pick).not_to be_best
    end

    it "is not eligible" do
      expect(pick).not_to be_eligible
    end
  end

  context "when the event occurred before its type was followed" do
    let(:subscribed_since) { 1.hour.ago }

    it "is not eligible" do
      expect(pick).not_to be_eligible
    end

    it "is not the best" do
      expect(pick).not_to be_best
    end
  end

  context "when the subscription only wants Russian" do
    let(:subscription) { create(:feed_subscription, languages: %w[ru]) }
    let!(:patch_notes) { create(:steam_news_event, watch:, story_key: "story-1", occurred_at: 2.hours.ago, language: "en") }
    let!(:article) { create(:steam_article_event, watch:, story_key: "story-1", occurred_at: 3.hours.ago, language: "ru") }

    it "does not find the English copy eligible" do
      expect(pick).not_to be_eligible
    end

    context "when asked about the Russian copy" do
      let(:event) { article }

      it "picks it over the filtered primary copy" do
        expect(pick).to be_best
      end
    end

    context "when the copy's language is unknown" do
      let!(:patch_notes) { create(:steam_news_event, watch:, story_key: "story-1", occurred_at: 2.hours.ago, language: nil) }

      it "stays eligible" do
        expect(pick).to be_eligible
      end
    end
  end

  context "when the event occurred after its type was followed" do
    it "is eligible" do
      expect(pick).to be_eligible
    end
  end

  context "when patch notes were followed after they were published but articles before the article was" do
    let(:event) { article }

    before do
      subscription.subscribed_events.find_by!(event_type: "Integrations::Steam::PatchNotesPublished").update!(subscribed_since: 1.hour.ago)
      subscription.subscribed_events.find_by!(event_type: "Integrations::Steam::ArticlePublished").update!(subscribed_since: 4.hours.ago)
    end

    it "makes the article eligible and the best copy, since the patch notes could never have been received" do
      expect(pick).to be_eligible
      expect(pick).to be_best
    end
  end

  describe "ranking by the secondary class attribute" do
    let(:event) { patch_notes }

    context "when the primary copy is the newer one" do
      let!(:patch_notes) { create(:steam_news_event, watch:, story_key: "story-1", occurred_at: 1.hour.ago) }

      it "still prefers it over the older secondary copy" do
        expect(pick).to be_best
      end
    end
  end
end
