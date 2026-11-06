# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::RevisePostJob do
  subject(:perform) { described_class.perform_now(post, event) }

  let(:watch) { create(:integration_watch, :twitch) }
  let(:event) { create(:twitch_stream_sampled_event, watch:) }
  let(:subscription) { create(:feed_subscription, :twitch, :active, watch:) }
  let(:post) { create(:feed_post, :sent, subscription:, story_key: event.story_key) }
  let(:other_post) { create(:feed_post, :sent, subscription:) }
  let(:later_event) { create(:twitch_stream_sampled_event, watch:) }

  before do
    allow(Ops::Feeds::Posts::Revise).to receive(:call)
  end

  it "revises the post with the event" do
    perform

    expect(Ops::Feeds::Posts::Revise).to have_received(:call).with(post:, event:)
  end

  describe "concurrency" do
    subject(:key) { described_class.new(post, event).concurrency_key }

    it "shares a key across the events of one post" do
      expect(described_class.new(post, later_event).concurrency_key).to eq(key)
    end

    it "differs between posts" do
      expect(described_class.new(other_post, event).concurrency_key).not_to eq(key)
    end
  end
end
