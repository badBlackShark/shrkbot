# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::StreamReconcileJob do
  subject(:perform) { described_class.perform_now }

  let(:watcher) { "Integrations::Twitch::ChannelWatcher" }
  let!(:live_watch) { create(:integration_watch, watcher:, external_id: "1", name: "Live One") }
  let!(:idle_watch) { create(:integration_watch, watcher:, external_id: "2", name: "Idle Two") }
  let(:demanded) { [live_watch, idle_watch] }
  let(:streams) { instance_double(Integrations::Twitch::Streams, live: [stream]) }
  let(:stream) do
    Integrations::Twitch::Stream.new(
      id: "s1",
      user_id: "1",
      user_login: "liveone",
      user_name: "Live One",
      category_id: "7",
      category_name: "Chess",
      title: "Ranked",
      viewer_count: 12,
      started_at: Time.zone.parse("2026-11-01 09:00:00"),
      thumbnail_url: "https://example.test/t.jpg"
    )
  end

  before do
    allow(Integrations::Twitch::Client).to receive(:configured?).and_return(true)
    allow(Integrations::Twitch::Streams).to receive(:new).and_return(streams)
    allow(Integrations::Watch).to receive(:demanded) { Integrations::Watch.where(id: demanded.map(&:id)) }
  end

  context "when Twitch is not configured" do
    before do
      allow(Integrations::Twitch::Client).to receive(:configured?).and_return(false)
    end

    it "asks Twitch for nothing" do
      perform

      expect(streams).not_to have_received(:live)
    end
  end

  context "when no Twitch channel is demanded" do
    let(:demanded) { [] }

    it "asks Twitch for nothing" do
      perform

      expect(streams).not_to have_received(:live)
    end
  end

  describe "concurrency" do
    it "gives every run the same key, so an overlapping run is discarded" do
      expect(described_class.new.concurrency_key).to eq(described_class.new.concurrency_key)
      expect(described_class).to have_attributes(concurrency_on_conflict: :discard)
    end
  end

  context "with a live channel and an offline one" do
    let!(:idle_watch) { create(:integration_watch, watcher:, external_id: "2", name: "Idle Two", state: {"session" => "old", "stream_ids" => ["old"], "peak_viewers" => 1, "started_at" => "2026-11-01T08:00:00Z", "last_live_at" => 10.minutes.ago.iso8601, "login" => "idle", "display_name" => "Idle Two"}) }

    it "starts a session for the live one" do
      perform

      expect(live_watch.reload.state).to include("session" => "s1", "category_name" => "Chess")
      expect(live_watch.events).to contain_exactly(an_instance_of(Integrations::Twitch::StreamStarted))
    end

    it "marks the offline one offline and schedules its close" do
      expect { perform }.to have_enqueued_job(Integrations::Twitch::CloseSessionJob).once
      expect(idle_watch.reload.state).to include("session" => "old", "offline_at" => be_present)
    end
  end

  context "with a Steam watch and an undemanded Twitch watch" do
    let!(:steam_watch) { create(:integration_watch, external_id: "3") }
    let!(:undemanded) { create(:integration_watch, watcher:, external_id: "4") }
    let(:demanded) { [live_watch, idle_watch, steam_watch] }

    it "asks only for the demanded Twitch channels" do
      perform

      expect(streams).to have_received(:live).with(match_array(%w[1 2]))
      expect(undemanded.reload.polled_at).to be_nil
    end
  end

  context "when the watches were failing" do
    let!(:live_watch) { create(:integration_watch, watcher:, external_id: "1", name: "Live One", failing_since: 2.hours.ago, polled_at: 1.hour.ago, last_error: "Integrations::Unavailable: 503") }

    it "clears the failure and stamps polled_at" do
      perform

      expect(live_watch.reload).to have_attributes(failing_since: nil, last_error: nil, polled_at: be_present)
    end
  end

  context "when Twitch is unavailable" do
    before do
      allow(streams).to receive(:live).and_raise(Integrations::Unavailable, "api.twitch.tv responded 503")
    end

    it "records the failure on every watch and transitions none" do
      perform

      expect(Integrations::Watch.where(watcher:)).to all(
        have_attributes(failing_since: be_present, last_error: "Integrations::Unavailable: api.twitch.tv responded 503", state: {})
      )
      expect(Integrations::Event.count).to eq(0)
    end
  end

  context "when Twitch rate limits the request" do
    before do
      allow(streams).to receive(:live).and_raise(Integrations::RateLimited.new("slow down", retry_after: 30))
    end

    it "reports it to the owner once and records the failure" do
      expect { perform }.to have_enqueued_job(Integrations::ReportRateLimitJob).with("Twitch streams", "slow down", 30).once
      expect(idle_watch.reload.last_error).to eq("Integrations::RateLimited: slow down")
    end

    context "when a watch other than the first was already rate limited" do
      let!(:idle_watch) do
        create(:integration_watch, watcher:, external_id: "2", name: "Idle Two", failing_since: 1.hour.ago, polled_at: 1.hour.ago, last_error: "Integrations::RateLimited: slow down")
      end

      it "does not report it again" do
        expect { perform }.not_to have_enqueued_job(Integrations::ReportRateLimitJob)
      end
    end

    context "when the watches were already rate limited" do
      let(:limited) { {failing_since: 1.hour.ago, polled_at: 1.hour.ago, last_error: "Integrations::RateLimited: slow down"} }
      let!(:live_watch) { create(:integration_watch, watcher:, external_id: "1", name: "Live One", **limited) }
      let!(:idle_watch) { create(:integration_watch, watcher:, external_id: "2", name: "Idle Two", **limited) }

      it "does not report it again" do
        expect { perform }.not_to have_enqueued_job(Integrations::ReportRateLimitJob)
      end
    end
  end

  context "when one watch's transition raises" do
    before do
      allow(Ops::Integrations::Twitch::Streams::Transition).to receive(:call).and_call_original
      allow(Ops::Integrations::Twitch::Streams::Transition).to receive(:call).with(hash_including(watch: live_watch)).and_raise(NoMethodError, "our bug")
    end

    let!(:idle_watch) { create(:integration_watch, watcher:, external_id: "2", name: "Idle Two", state: {"session" => "old", "stream_ids" => ["old"], "peak_viewers" => 1, "started_at" => "2026-11-01T08:00:00Z", "last_live_at" => 10.minutes.ago.iso8601, "login" => "idle", "display_name" => "Idle Two"}) }

    it "records the failure on the broken watch" do
      perform

      expect(live_watch.reload.last_error).to eq("NoMethodError: our bug")
    end

    it "does not report the same bug again on the next run" do
      described_class.perform_now
      expect { perform }.not_to have_enqueued_job(Integrations::ReportPollBugsJob)
    end

    it "still transitions the other and reports the bug once" do
      expect { perform }.to have_enqueued_job(Integrations::ReportPollBugsJob)
        .with(["Live One (1): NoMethodError: our bug"])
        .once
      expect(idle_watch.reload.state).to have_key("offline_at")
    end
  end
end
