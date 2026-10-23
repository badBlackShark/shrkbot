# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Steam::Stories do
  subject(:assigned) { described_class.new(recent).assign(events) }

  let(:watch) { create(:integration_watch) }
  let(:recent) { [] }
  let(:base) { Time.zone.parse("2026-10-20 10:00:00") }
  let(:community) { "steam_community_announcements" }

  def event(subject_key, feed_name, minutes, title: "Update Released")
    build(
      :steam_news_event,
      watch:,
      subject_key:,
      feed_name:,
      title:,
      occurred_at: base + minutes.minutes,
      story_key: nil
    )
  end

  def story_keys
    assigned.map(&:story_key)
  end

  context "with the same update arriving through three feeds within a minute" do
    let(:events) { [event("c", community, 0), event("u", "steam_updates", -1), event("b", "tf2_blog", 0)] }

    it "gives all three the key of the earliest" do
      expect(story_keys).to all(eq("u"))
    end
  end

  context "with the same feed and title five minutes apart" do
    let(:events) { [event("a", community, 0), event("b", community, 5)] }

    it "keeps them as separate stories" do
      expect(story_keys).to eq(%w[a b])
    end
  end

  context "with different feeds sixteen minutes apart" do
    let(:events) { [event("a", community, 0), event("b", "tf2_blog", 16)] }

    it "keeps them as separate stories" do
      expect(story_keys).to eq(%w[a b])
    end
  end

  context "with different feeds fifteen minutes apart" do
    let(:events) { [event("a", community, 0), event("b", "tf2_blog", 15)] }

    it "links them" do
      expect(story_keys).to eq(%w[a a])
    end
  end

  context "when the other half arrived in an earlier poll" do
    let(:recent) { [create(:steam_news_event, watch:, subject_key: "a", feed_name: community, title: "Update Released", occurred_at: base)] }
    let(:events) { [event("b", "tf2_blog", 3)] }

    it "joins the persisted event's story" do
      expect(story_keys).to eq(%w[a])
    end
  end

  context "when a story already holds the event's feed" do
    let(:events) do
      [
        event("A", community, 0),
        event("C1", "steam_updates", 1),
        event("B", community, 5),
        event("C2", "steam_updates", 6)
      ]
    end

    it "starts a new story for the second community post and attaches the second mirror to it" do
      expect(story_keys).to eq(%w[A A B B])
    end
  end

  context "with titles that differ only in case and punctuation" do
    let(:events) { [event("a", community, 0, title: "Update: Released!"), event("b", "tf2_blog", 1, title: "update released")] }

    it "treats them as the same title" do
      expect(story_keys).to eq(%w[a a])
    end
  end

  context "with different titles" do
    let(:events) { [event("a", community, 0, title: "Patch 1"), event("b", "tf2_blog", 1, title: "Patch 2")] }

    it "keeps them as separate stories" do
      expect(story_keys).to eq(%w[a b])
    end
  end

  context "when an item was already observed" do
    let(:recent) do
      [
        create(:steam_news_event, watch:, subject_key: "a", feed_name: community, occurred_at: base, story_key: "earlier"),
        create(:steam_news_event, watch:, subject_key: "x", feed_name: "tf2_blog", occurred_at: base, story_key: "other")
      ]
    end
    let(:events) { [event("a", community, 0)] }

    it "copies the stored story key instead of re-deriving it" do
      expect(story_keys).to eq(%w[earlier])
    end
  end
end
