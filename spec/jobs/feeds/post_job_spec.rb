# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe Feeds::PostJob do
  subject(:perform) { described_class.perform_now(subscription, event) }

  let(:watch) { create(:integration_watch) }
  let(:subscription) { create(:feed_subscription, :active, watch:) }
  let(:subscribed_types) { %w[Integrations::Steam::PatchNotesPublished Integrations::Steam::ArticlePublished] }
  let!(:patch_notes) { create(:steam_news_event, watch:, story_key: "story-1") }
  let!(:article) { create(:steam_article_event, watch:, story_key: "story-1") }
  let(:event) { patch_notes }
  let(:subscribed_since) { 1.day.ago }

  before do
    subscribed_types.each do |event_type|
      create(:feed_subscribed_event, subscription:, event_type:, subscribed_since:)
    end
    allow(Feeds::Steam::Thumbnail).to receive(:for).and_return(nil)
    allow(Bot::Discord::Components).to receive(:create_with_subject).and_return(777_000)
  end

  it "posts the story" do
    perform

    expect(Bot::Discord::Components).to have_received(:create_with_subject).once
    expect(subscription.posts.pluck(:story_key)).to eq(["story-1"])
  end

  context "when the subscription is no longer active" do
    let(:subscription) { create(:feed_subscription, watch:) }

    it "sends nothing" do
      perform

      expect(Bot::Discord::Components).not_to have_received(:create_with_subject)
    end
  end

  context "when the story was already posted" do
    before do
      create(:feed_post, subscription:, story_key: "story-1")
    end

    it "sends nothing" do
      perform

      expect(Bot::Discord::Components).not_to have_received(:create_with_subject)
    end
  end

  context "when a better copy of the story is subscribed" do
    let(:event) { article }

    it "sends nothing" do
      perform

      expect(Bot::Discord::Components).not_to have_received(:create_with_subject)
    end
  end

  context "when the event's type was followed after the event occurred" do
    let(:subscribed_since) { 1.minute.from_now }

    it "sends nothing" do
      perform

      expect(Bot::Discord::Components).not_to have_received(:create_with_subject)
    end
  end

  context "when the event's type is not followed at all" do
    let(:subscribed_types) { %w[Integrations::Steam::ArticlePublished] }

    it "sends nothing" do
      perform

      expect(Bot::Discord::Components).not_to have_received(:create_with_subject)
    end
  end

  context "when only the article type is subscribed" do
    let(:subscribed_types) { %w[Integrations::Steam::ArticlePublished] }
    let(:event) { article }

    it "posts the article" do
      perform

      expect(subscription.posts.pluck(:story_key)).to eq(["story-1"])
    end
  end

  context "when the event was pruned before the job ran" do
    subject(:perform) { ActiveJob::Base.execute(serialized) }

    let!(:serialized) { described_class.new(subscription, event).serialize }

    before do
      event.destroy!
    end

    it "is discarded" do
      expect { perform }.not_to raise_error
      expect(Bot::Discord::Components).not_to have_received(:create_with_subject)
    end
  end

  context "for a Twitch stream" do
    let(:watch) { create(:integration_watch, :twitch, state: watch_state) }
    let(:subscription) { create(:feed_subscription, :active, :twitch, watch:) }
    let(:event) { create(:twitch_stream_started_event, watch:, session: "9001") }
    let(:subscribed_types) { %w[Integrations::Twitch::StreamStarted] }
    let(:watch_state) { {"session" => "9001"} }

    before do
      allow(Feeds::Twitch::LiveImage).to receive(:for).and_return(nil)
    end

    it "posts while the stream's session is the open one" do
      perform

      expect(subscription.posts.pluck(:story_key)).to eq(["stream:9001"])
    end

    context "when the session already ended" do
      let(:watch_state) { {} }

      it "sends nothing and records no post" do
        perform

        expect(Bot::Discord::Components).not_to have_received(:create_with_subject)
        expect(subscription.posts).to be_empty
      end
    end

    context "when a category switch comes from a session that is no longer open" do
      let(:event) { create(:twitch_stream_updated_event, watch:, session: "9001") }
      let(:watch_state) { {"session" => "other"} }

      it "sends nothing" do
        perform

        expect(Bot::Discord::Components).not_to have_received(:create_with_subject)
      end
    end

    context "when a newer session is open" do
      let(:watch_state) { {"session" => "other"} }

      it "sends nothing" do
        perform

        expect(Bot::Discord::Components).not_to have_received(:create_with_subject)
      end
    end
  end

  describe "concurrency" do
    subject(:key) { described_class.new(subscription, patch_notes).concurrency_key }

    let(:other_story) { create(:steam_news_event, watch:, story_key: "story-2") }
    let(:other_subscription) { create(:feed_subscription, :active, watch:) }

    it "shares a key across the stories of one subscription" do
      expect(described_class.new(subscription, other_story).concurrency_key).to eq(key)
    end

    it "differs between subscriptions" do
      expect(described_class.new(other_subscription, patch_notes).concurrency_key).not_to eq(key)
    end
  end
end
