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

  before do
    subscribed_types.each do |event_type|
      create(:feed_subscribed_event, subscription:, event_type:)
    end
    allow(Bot::Discord::Components).to receive_messages(create_message: 777_000, convert_to_v2: nil)
  end

  it "posts the story" do
    perform

    expect(Bot::Discord::Components).to have_received(:create_message).once
    expect(subscription.posts.pluck(:story_key)).to eq(["story-1"])
  end

  context "when the story was already posted" do
    before do
      create(:feed_post, subscription:, story_key: "story-1")
    end

    it "sends nothing" do
      perform

      expect(Bot::Discord::Components).not_to have_received(:create_message)
    end
  end

  context "when a better copy of the story is subscribed" do
    let(:event) { article }

    it "sends nothing" do
      perform

      expect(Bot::Discord::Components).not_to have_received(:create_message)
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
      expect(Bot::Discord::Components).not_to have_received(:create_message)
    end
  end

  it "keys concurrency by subscription and story, so two copies of one story never post together" do
    key = described_class.concurrency_key.call(subscription, event)

    expect(key).to eq("#{subscription.id}-story-1")
  end
end
