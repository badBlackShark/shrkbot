# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::Session do
  subject(:outcome) { described_class.new(state, now:).apply(observation) }

  let(:now) { Time.zone.parse("2026-11-01 12:00:00") }
  let(:started_at) { Time.zone.parse("2026-11-01 09:00:00") }
  let(:last_live_at) { now - 10.minutes }
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
      "last_live_at" => last_live_at.iso8601,
      "login" => "shroud",
      "display_name" => "Shroud",
      "peak_viewers" => 100
    }
  end
  let(:offline_at) { now - 4.minutes }
  let(:offline_state) { open_state.merge("offline_at" => offline_at.iso8601) }
  let(:closed_state) { {"login" => "shroud", "display_name" => "Shroud"} }

  context "when live with no session" do
    it "starts one, stamping the sighting" do
      expect(outcome.state).to eq(open_state.merge("last_live_at" => now.iso8601))
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

  context "when live in a session seen recently" do
    let(:state) { open_state }

    it "keeps the session, stamps the sighting and emits nothing" do
      expect(outcome.state).to eq(open_state.merge("last_live_at" => now.iso8601))
      expect(outcome.events).to be_empty
    end

    context "with more viewers" do
      let(:observation) { live.with(viewer_count: 250) }

      it "raises the peak without an event" do
        expect(outcome.state["peak_viewers"]).to eq(250)
        expect(outcome.events).to be_empty
      end
    end

    context "with fewer viewers" do
      let(:observation) { live.with(viewer_count: 40) }

      it "keeps the peak" do
        expect(outcome.state["peak_viewers"]).to eq(100)
      end
    end

    context "with a new title" do
      let(:observation) { live.with(title: "Casual") }

      it "stores it and emits StreamUpdated" do
        expect(outcome.state["title"]).to eq("Casual")
        expect(outcome.events).to match([
          an_instance_of(Integrations::Twitch::StreamUpdated).and(
            have_attributes(subject_key: "stream-update:s1:#{now.to_i}", occurred_at: now, title: "Casual", story_key: "stream:s1")
          )
        ])
      end
    end

    context "with a new category" do
      let(:observation) { live.with(category_id: "2", category_name: "Just Chatting") }

      it "stores it and emits StreamUpdated" do
        expect(outcome.state).to include("category_id" => "2", "category_name" => "Just Chatting")
        expect(outcome.events.map(&:class)).to eq([Integrations::Twitch::StreamUpdated])
      end
    end
  end

  context "when a reconnect with a new stream id follows an offline sighting" do
    let(:state) { offline_state.merge("last_live_at" => (now - 14.minutes).iso8601) }
    let(:observation) { live.with(stream_id: "s2") }

    it "stays in the session without an event" do
      expect(outcome.state).to include("session" => "s1", "stream_ids" => %w[s1 s2], "last_live_at" => now.iso8601)
      expect(outcome.state).not_to have_key("offline_at")
      expect(outcome.events).to be_empty
    end
  end

  context "when a new stream id arrives long after the last sighting" do
    let(:last_live_at) { now - 1.day }
    let(:state) { open_state }
    let(:observation) { live.with(stream_id: "s2", started_at: now - 2.minutes) }

    it "ends the old session at its last sighting and starts the new one" do
      expect(outcome.events).to match([
        an_instance_of(Integrations::Twitch::StreamEnded).and(
          have_attributes(subject_key: "stream-end:s1", occurred_at: last_live_at, duration: (last_live_at - started_at).to_i)
        ),
        an_instance_of(Integrations::Twitch::StreamStarted).and(have_attributes(subject_key: "stream:s2"))
      ])
      expect(outcome.state).to include("session" => "s2", "stream_ids" => ["s2"])
    end
  end

  context "when the session's own stream id reappears after a long gap" do
    let(:last_live_at) { now - 1.hour }
    let(:state) { open_state }

    it "keeps the session, because the stream never ended" do
      expect(outcome.state).to include("session" => "s1", "last_live_at" => now.iso8601)
      expect(outcome.events).to be_empty
    end
  end

  context "when offline with no session" do
    let(:observation) { Integrations::Twitch::Offline.new }
    let(:state) { closed_state }

    it "does nothing" do
      expect(outcome).to have_attributes(state: closed_state, events: [], went_offline: false)
    end
  end

  context "when offline for the first time in a session" do
    let(:observation) { Integrations::Twitch::Offline.new }
    let(:state) { open_state }

    it "marks the time and asks for a close check" do
      expect(outcome.state).to eq(open_state.merge("offline_at" => now.iso8601))
      expect(outcome.events).to be_empty
      expect(outcome.went_offline).to be(true)
    end
  end

  context "when offline again before the close check" do
    let(:observation) { Integrations::Twitch::Offline.new }
    let(:state) { offline_state }

    it "does nothing" do
      expect(outcome).to have_attributes(state: offline_state, events: [], went_offline: false)
    end
  end

  context "when offline long after the last sighting" do
    let(:observation) { Integrations::Twitch::Offline.new }
    let(:last_live_at) { now - 1.day }
    let(:state) { open_state }

    it "ends the session at the last sighting, so the duration stays true" do
      expect(outcome.events).to match([
        an_instance_of(Integrations::Twitch::StreamEnded).and(
          have_attributes(occurred_at: last_live_at, ended_at: last_live_at.iso8601, duration: (last_live_at - started_at).to_i)
        )
      ])
      expect(outcome.state).to eq(closed_state)
    end
  end

  context "when the close check confirms the offline sighting" do
    let(:observation) { Integrations::Twitch::Close.new(offline_since: offline_at.iso8601) }
    let(:state) { offline_state }

    it "ends the session at the offline sighting" do
      expect(outcome.events).to match([
        an_instance_of(Integrations::Twitch::StreamEnded).and(
          have_attributes(
            subject_key: "stream-end:s1",
            occurred_at: offline_at,
            ended_at: offline_at.iso8601,
            duration: (offline_at - started_at).to_i,
            peak_viewers: 100,
            story_key: "stream:s1"
          )
        )
      ])
      expect(outcome.state).to eq(closed_state)
    end
  end

  context "when the close check names an older offline sighting" do
    let(:observation) { Integrations::Twitch::Close.new(offline_since: (offline_at - 1.hour).iso8601) }
    let(:state) { offline_state }

    it "does nothing" do
      expect(outcome).to have_attributes(state: offline_state, events: [])
    end
  end

  context "when the close check finds the channel back live" do
    let(:observation) { Integrations::Twitch::Close.new(offline_since: offline_at.iso8601) }
    let(:state) { open_state }

    it "does nothing" do
      expect(outcome).to have_attributes(state: open_state, events: [])
    end
  end

  context "with an observation it does not know" do
    let(:observation) { Object.new }

    it "fails loudly" do
      expect { outcome }.to raise_error(NoMatchingPatternError)
    end
  end
end
