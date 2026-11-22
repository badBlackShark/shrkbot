# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::AnnounceJob do
  subject(:perform) { described_class.perform_now(event) }

  let(:watch) { create(:integration_watch) }
  let(:event) { create(:steam_news_event, watch:) }
  let!(:subscription) { create(:feed_subscription, :active, watch:) }
  let!(:subscribed_event) { create(:feed_subscribed_event, subscription:, event_type: event.type) }

  it "enqueues one post job per active subscription following the watch and the event type" do
    expect { perform }.to have_enqueued_job(Feeds::PostJob).once.with(subscription, event)
  end

  context "when a Twitch stream switches category" do
    let(:watch) { create(:integration_watch, :twitch) }
    let(:event) { create(:twitch_stream_updated_event, watch:) }
    let!(:subscription) { create(:feed_subscription, :active, :twitch, watch:) }
    let!(:subscribed_event) { create(:feed_subscribed_event, subscription:, event_type: "Integrations::Twitch::StreamStarted") }

    it "enqueues a post job for the subscription following Live" do
      expect { perform }.to have_enqueued_job(Feeds::PostJob).once.with(subscription, event)
    end

    context "when the subscription already posted the stream" do
      before do
        create(:feed_post, subscription:, story_key: event.story_key)
      end

      it "enqueues nothing" do
        expect { perform }.not_to have_enqueued_job(Feeds::PostJob)
      end
    end
  end

  describe "a stream found through a followed category" do
    let(:watch) { create(:integration_watch, :twitch) }
    let(:live) { "Integrations::Twitch::StreamStarted" }
    let(:category_watch) { create(:integration_watch, :twitch_category) }
    let(:other_category_watch) { create(:integration_watch, :twitch_category) }
    let(:event) { create(:twitch_stream_started_event, watch:, category_id: category_watch.external_id) }
    let!(:direct) { create(:feed_subscription, :active, :twitch, watch:) }
    let!(:category_follow) { create(:feed_subscription, :active, :twitch_category, watch: category_watch) }
    let!(:other_category_follow) { create(:feed_subscription, :active, :twitch_category, watch: other_category_watch) }
    let!(:subscription) { nil }
    let!(:subscribed_event) { nil }

    let(:enqueued_subscription_ids) do
      ActiveJob::Base.queue_adapter.enqueued_jobs
        .select { |job| job["job_class"] == "Feeds::PostJob" }
        .map { |job| job["arguments"].first["_aj_globalid"] }
    end

    before do
      [direct, category_follow, other_category_follow].each do |follow|
        create(:feed_subscribed_event, subscription: follow, event_type: live)
      end
      ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    end

    context "when the stream starts" do
      it "reaches the channel follow and the follow of its category, not another category's" do
        perform

        expect(enqueued_subscription_ids).to contain_exactly(direct.to_global_id.to_s, category_follow.to_global_id.to_s)
      end
    end

    context "when a sample crosses a floor" do
      let(:event) { create(:twitch_stream_sampled_event, watch:, category_id: category_watch.external_id) }

      it "reaches only the category follow" do
        expect { perform }.to have_enqueued_job(Feeds::PostJob).once.with(category_follow, event)
      end
    end

    context "when the category follow already posted the story" do
      before { create(:feed_post, subscription: category_follow, story_key: event.story_key) }

      it "reaches only the channel follow" do
        expect { perform }.to have_enqueued_job(Feeds::PostJob).once.with(direct, event)
      end
    end
  end

  context "when the subscription is inactive" do
    let!(:subscription) { create(:feed_subscription, watch:) }

    it "enqueues nothing" do
      expect { perform }.not_to have_enqueued_job(Feeds::PostJob)
    end
  end

  context "when the subscription does not follow the event type" do
    let!(:subscribed_event) { create(:feed_subscribed_event, subscription:, event_type: "Integrations::Steam::ArticlePublished") }

    it "enqueues nothing" do
      expect { perform }.not_to have_enqueued_job(Feeds::PostJob)
    end
  end

  context "when the subscription follows another watch" do
    let!(:subscription) { create(:feed_subscription, :active) }

    it "enqueues nothing" do
      expect { perform }.not_to have_enqueued_job(Feeds::PostJob)
    end
  end

  context "when several servers follow the watch" do
    let!(:other) { create(:feed_subscription, :active, watch:) }

    before do
      create(:feed_subscribed_event, subscription: other, event_type: event.type)
    end

    it "enqueues a post job for each" do
      expect { perform }.to change { ActiveJob::Base.queue_adapter.enqueued_jobs.size }.by(2)
    end
  end

  describe "concurrency" do
    subject(:key) { described_class.new(event).concurrency_key }

    let(:same_watch_event) { create(:steam_news_event, watch:) }
    let(:other_watch_event) { create(:steam_news_event) }

    it "shares a key across the events of one watch" do
      expect(described_class.new(same_watch_event).concurrency_key).to eq(key)
    end

    it "differs between watches" do
      expect(described_class.new(other_watch_event).concurrency_key).not_to eq(key)
    end
  end

  context "when the event was pruned before the job ran" do
    subject(:perform) { ActiveJob::Base.execute(serialized) }

    let!(:serialized) { described_class.new(event).serialize }

    before do
      event.destroy!
    end

    it "is discarded" do
      expect { perform }.not_to raise_error
    end
  end
end
