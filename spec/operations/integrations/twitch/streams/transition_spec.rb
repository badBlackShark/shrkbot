# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Integrations::Twitch::Streams::Transition do
  include ActiveSupport::Testing::TimeHelpers

  subject(:result) { described_class.call(watch:, observation:) }

  let(:watch) { create(:integration_watch, watcher: "Integrations::Twitch::ChannelWatcher", external_id: "99", name: "Shroud", state:) }
  let(:state) { {} }
  let(:started_at) { Time.zone.parse("2026-11-01 09:00:00") }
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
  let(:going_offline) { Integrations::Twitch::Offline.new }

  around do |example|
    travel_to(Time.zone.parse("2026-11-01 12:00:00")) { example.run }
  end

  context "when the stream event would be invalid" do
    let(:observation) { live.with(login: nil) }

    before { allow(Rails.logger).to receive(:warn) }

    it "raises and leaves the watch idle, so the start is not lost silently" do
      expect { result }.to raise_error(described_class::DroppedEvent)
      expect(watch.reload.state).to eq({})
    end
  end

  context "when a closed session's stream shows up live again" do
    let(:state) { {"login" => "shroud", "display_name" => "Shroud"} }

    before do
      Integrations::Twitch::StreamStarted.create!(
        watch:,
        subject_key: "stream:s1",
        occurred_at: started_at,
        session: "s1",
        login: "shroud",
        display_name: "Shroud",
        story_key: "stream:s1"
      )
    end

    it "reopens the session without breaking on the already stored start" do
      expect { result }.not_to change { Integrations::Event.where(watch:).count }
      expect(watch.reload.state).to include("session" => "s1")
    end
  end

  context "with a live stream on an idle watch" do
    it "saves the session state and a StreamStarted for the watch" do
      result

      expect(watch.reload.state).to include("session" => "s1", "peak_viewers" => 100)
      expect(Integrations::Event.where(watch:)).to contain_exactly(an_instance_of(Integrations::Twitch::StreamStarted))
    end
  end

  context "with an offline observation inside a session" do
    let(:observation) { going_offline }
    let(:state) { {"session" => "s1", "stream_ids" => ["s1"], "last_live_at" => 8.minutes.ago.iso8601, "peak_viewers" => 5, "started_at" => started_at.iso8601, "login" => "shroud", "display_name" => "Shroud"} }
    let(:offline_at) { Time.current.iso8601 }

    it "stamps offline_at and schedules the close for the end of the grace period" do
      expect { result }.to have_enqueued_job(Integrations::Twitch::CloseSessionJob)
        .with(watch, offline_at)
        .at(Integrations::Twitch::Session::GRACE.from_now)
      expect(watch.reload.state.fetch("offline_at")).to eq(offline_at)
    end

    context "when a second offline arrives inside the grace period" do
      let(:state) { super().merge("offline_at" => 2.minutes.ago.iso8601) }

      it "schedules nothing new" do
        expect { result }.not_to have_enqueued_job(Integrations::Twitch::CloseSessionJob)
      end
    end
  end

  context "with a close for the matching offline" do
    let(:offline_at) { 5.minutes.ago }
    let(:observation) { Integrations::Twitch::Close.new(offline_since: offline_at.iso8601) }
    let(:state) do
      {
        "session" => "s1",
        "stream_ids" => ["s1"], "last_live_at" => 8.minutes.ago.iso8601,
        "peak_viewers" => 5,
        "started_at" => started_at.iso8601,
        "login" => "shroud",
        "display_name" => "Shroud",
        "offline_at" => offline_at.iso8601
      }
    end

    it "ends the session and records StreamEnded" do
      result

      expect(watch.reload.state).to eq("login" => "shroud", "display_name" => "Shroud", "ended_stream_ids" => ["s1"])
      expect(Integrations::Event.where(watch:)).to contain_exactly(an_instance_of(Integrations::Twitch::StreamEnded))
    end
  end
end
