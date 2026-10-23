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
