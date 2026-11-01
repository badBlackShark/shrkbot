# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::Session do
  subject(:outcome) { described_class.new(state, now:).apply(observation) }

  let(:now) { Time.zone.parse("2026-11-01 12:00:00") }
  let(:started_at) { Time.zone.parse("2026-11-01 09:00:00") }
  let(:state) { {} }
  let(:observation) { live }
  let(:live) do
    Integrations::Twitch::Live.new(
      stream_id: "s1",
      started_at:,
      title: "Ranked",
      category_id: "1",
      category_name: "Chess",
      login: "shroud",
      display_name: "Shroud",
      viewer_count: 100
    )
  end
  let(:open_state) do
    {
      "session" => "s1",
      "stream_ids" => ["s1"],
      "title" => "Ranked",
      "category_id" => "1",
      "category_name" => "Chess",
      "started_at" => started_at.iso8601,
      "login" => "shroud",
      "display_name" => "Shroud",
      "peak_viewers" => 100
    }
  end
  let(:offline_state) { open_state.merge("offline_at" => offline_at.iso8601) }
  let(:offline_at) { now - 4.minutes }

  context "when live with no session" do
    it "starts one" do
      expect(outcome.state).to eq(open_state)
      expect(outcome.went_offline).to be(false)
    end

    it "emits StreamStarted at the stream's start" do
      expect(outcome.events).to match([
        an_instance_of(Integrations::Twitch::StreamStarted).and(
          have_attributes(
            subject_key: "stream:s1",
            occurred_at: started_at,
            session: "s1",
            login: "shroud",
            display_name: "Shroud",
            title: "Ranked",
            category_id: "1",
            category_name: "Chess",
            started_at: started_at.iso8601,
            story_key: "stream:s1"
          )
        )
      ])
    end
  end

  context "when live inside a session" do
    let(:state) { open_state }

    context "with the same stream and nothing changed but the viewers" do
      let(:observation) { live.with(viewer_count: 250) }

      it "raises the peak and emits nothing" do
        expect(outcome.state).to eq(open_state.merge("peak_viewers" => 250))
        expect(outcome.events).to be_empty
      end
    end

    context "with fewer viewers than the peak" do
      let(:observation) { live.with(viewer_count: 10) }

      it "keeps the peak" do
        expect(outcome.state.fetch("peak_viewers")).to eq(100)
      end
    end

    context "with a new title" do
      let(:observation) { live.with(title: "Chill") }

      it "stores it and emits StreamUpdated stamped with now" do
        expect(outcome.state.fetch("title")).to eq("Chill")
        expect(outcome.events).to match([
          an_instance_of(Integrations::Twitch::StreamUpdated).and(
            have_attributes(
              subject_key: "stream-update:s1:#{now.to_i}",
              occurred_at: now,
              title: "Chill",
              story_key: "stream:s1"
            )
          )
        ])
      end
    end

    context "with a new category" do
      let(:observation) { live.with(category_id: "2", category_name: "Go") }

      it "stores it and emits StreamUpdated" do
        expect(outcome.state).to include("category_id" => "2", "category_name" => "Go")
        expect(outcome.events.map(&:class)).to eq([Integrations::Twitch::StreamUpdated])
        expect(outcome.events.first).to have_attributes(category_id: "2", category_name: "Go")
      end
    end

    context "with a new stream id and no offline seen" do
      let(:observation) { live.with(stream_id: "s2") }

      it "merges it into the session" do
        expect(outcome.state).to include("session" => "s1", "stream_ids" => %w[s1 s2])
        expect(outcome.events).to be_empty
      end
    end

    context "when the display name changed" do
      let(:observation) { live.with(display_name: "SHROUD") }

      it "follows it without an event" do
        expect(outcome.state.fetch("display_name")).to eq("SHROUD")
        expect(outcome.events).to be_empty
      end
    end
  end

  context "when live after an offline" do
    let(:state) { offline_state }
    let(:observation) { live.with(stream_id: "s2", started_at: now - 1.minute) }

    context "with the reconnect inside the grace period" do
      it "merges the new stream, clears offline_at and emits nothing" do
        expect(outcome.state).to eq(open_state.merge("stream_ids" => %w[s1 s2]))
        expect(outcome.events).to be_empty
      end
    end

    context "with the reconnect after the grace period" do
      let(:offline_at) { now - 6.minutes }

      it "ends the old session at offline_at and starts a new one" do
        expect(outcome.events.map(&:class)).to eq([Integrations::Twitch::StreamEnded, Integrations::Twitch::StreamStarted])
        expect(outcome.events.first).to have_attributes(subject_key: "stream-end:s1", occurred_at: offline_at)
        expect(outcome.events.last).to have_attributes(subject_key: "stream:s2", session: "s2")
        expect(outcome.state).to include("session" => "s2", "stream_ids" => ["s2"])
        expect(outcome.state).not_to have_key("offline_at")
      end
    end
  end

  context "when offline with no session" do
    let(:observation) { Integrations::Twitch::Offline.new }

    it "does nothing" do
      expect(outcome).to have_attributes(state: {}, events: [], went_offline: false)
    end
  end

  context "when offline inside a session" do
    let(:observation) { Integrations::Twitch::Offline.new }
    let(:state) { open_state }

    it "stamps offline_at and reports it went offline, without events" do
      expect(outcome.state).to eq(open_state.merge("offline_at" => now.iso8601))
      expect(outcome).to have_attributes(events: [], went_offline: true)
    end

    context "with an offline already seen inside the grace period" do
      let(:state) { offline_state }

      it "does nothing" do
        expect(outcome).to have_attributes(state: offline_state, events: [], went_offline: false)
      end
    end

    context "with an offline seen a full grace period ago" do
      let(:state) { offline_state }
      let(:offline_at) { now - described_class::GRACE }

      it "ends the session" do
        expect(outcome.events.map(&:class)).to eq([Integrations::Twitch::StreamEnded])
        expect(outcome.state).to eq("login" => "shroud", "display_name" => "Shroud")
      end
    end
  end

  describe "the ended event" do
    subject(:ended) { outcome.events.first }

    let(:observation) { Integrations::Twitch::Close.new(offline_since: offline_at.iso8601) }
    let(:state) { offline_state.merge("peak_viewers" => 420) }
    let(:offline_at) { now - 5.minutes }

    it "carries the offline time, the duration and the peak" do
      expect(ended).to have_attributes(
        subject_key: "stream-end:s1",
        occurred_at: offline_at,
        ended_at: offline_at.iso8601,
        duration: (2.hours + 55.minutes).to_i,
        peak_viewers: 420,
        title: "Ranked",
        story_key: "stream:s1"
      )
    end
  end

  context "when closing" do
    let(:observation) { Integrations::Twitch::Close.new(offline_since: offline_at.iso8601) }
    let(:state) { offline_state }
    let(:offline_at) { now - 5.minutes }

    it "ends the session whose offline matches" do
      expect(outcome.events.map(&:class)).to eq([Integrations::Twitch::StreamEnded])
      expect(outcome.state).to eq("login" => "shroud", "display_name" => "Shroud")
    end

    context "with a stale offline_since" do
      let(:observation) { Integrations::Twitch::Close.new(offline_since: (offline_at - 1.hour).iso8601) }

      it "does nothing" do
        expect(outcome).to have_attributes(state: offline_state, events: [])
      end
    end

    context "when the stream is back" do
      let(:state) { open_state }

      it "does nothing" do
        expect(outcome).to have_attributes(state: open_state, events: [])
      end
    end

    context "when the session already ended" do
      let(:state) { {"login" => "shroud", "display_name" => "Shroud"} }

      it "does nothing" do
        expect(outcome).to have_attributes(state:, events: [])
      end
    end
  end

  context "with an observation it does not know" do
    let(:observation) { Object.new }

    it "fails loudly" do
      expect { outcome }.to raise_error(NoMatchingPatternError)
    end
  end
end
