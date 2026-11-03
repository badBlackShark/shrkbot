# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::ReviseJob do
  subject(:perform) { described_class.perform_now(event) }

  let(:watch) { create(:integration_watch, :twitch) }
  let(:event) { create(:twitch_stream_sampled_event, watch:) }
  let!(:subscription) { create(:feed_subscription, :twitch, :active, watch:) }
  let!(:post) { create(:feed_post, :sent, subscription:, story_key: event.story_key) }

  it "enqueues one revise job per sent post of the story" do
    expect { perform }.to have_enqueued_job(Feeds::RevisePostJob).once.with(post, event)
  end

  context "when the post is still being sent" do
    let!(:post) { create(:feed_post, subscription:, story_key: event.story_key) }

    it "enqueues nothing" do
      expect { perform }.not_to have_enqueued_job(Feeds::RevisePostJob)
    end
  end

  context "when the subscription is inactive" do
    let!(:subscription) { create(:feed_subscription, :twitch, watch:) }

    it "enqueues nothing" do
      expect { perform }.not_to have_enqueued_job(Feeds::RevisePostJob)
    end
  end

  context "when the post belongs to another story" do
    let!(:post) { create(:feed_post, :sent, subscription:, story_key: "stream:other") }

    it "enqueues nothing" do
      expect { perform }.not_to have_enqueued_job(Feeds::RevisePostJob)
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
