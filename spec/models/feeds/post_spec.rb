# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Post do
  subject(:post) { build(:feed_post, subscription:, story_key:) }

  let(:subscription) { create(:feed_subscription) }
  let(:story_key) { "story-1" }

  it { is_expected.to be_valid }

  context "without a story key" do
    let(:story_key) { nil }

    it { is_expected.not_to be_valid }
  end

  context "when the subscription already posted the story" do
    before do
      create(:feed_post, subscription:, story_key:)
    end

    it { is_expected.not_to be_valid }
  end

  context "when another subscription posted the same story" do
    before do
      create(:feed_post, story_key:)
    end

    it { is_expected.to be_valid }
  end
end
