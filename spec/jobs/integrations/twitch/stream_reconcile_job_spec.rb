# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::StreamReconcileJob do
  include ActiveSupport::Testing::TimeHelpers

  subject(:perform) { described_class.perform_now }

  let(:watcher) { "Integrations::Twitch::ChannelWatcher" }
  let!(:live_watch) { create(:integration_watch, watcher:, external_id: "1", name: "Live One") }
  let!(:idle_watch) { create(:integration_watch, watcher:, external_id: "2", name: "Idle Two") }
  let(:live) { [live_watch, idle_watch] }
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
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    allow(Integrations::Twitch::Client).to receive(:configured?).and_return(true)
    allow(Integrations::Twitch::Streams).to receive(:new).and_return(streams)
    allow(Integrations::Twitch::ChannelWatcher).to receive(:live_checked) { Integrations::Watch.where(id: live.map(&:id)) }
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

  context "when no Twitch channel is followed for Live" do
    let(:live) { [] }

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

  context "when Twitch is unavailable" do
    before do
      allow(streams).to receive(:live).and_raise(Integrations::Unavailable, "api.twitch.tv responded 503")
    end

    it "does not claim the credentials were rejected" do
      expect { perform }.not_to have_enqueued_job(Integrations::Twitch::ReportUnauthorizedJob)
    end

    it "leaves every watch's health untouched and transitions none" do
      perform

      expect(Integrations::Watch.where(watcher:)).to all(
        have_attributes(failing_since: nil, last_error: nil, polled_at: nil, state: {})
      )
      expect(Integrations::Event.count).to eq(0)
    end

    describe "the broken live check report" do
      let(:failing_for) { 22.hours }

      before do
        freeze_time
        described_class.perform_now
        (failing_for / 2.hours).times do
          travel 2.hours
          described_class.perform_now
        end
        travel 2.hours
      end

      it "tells the owner once the check has failed for 24 hours" do
        expect { perform }.to have_enqueued_job(Integrations::Twitch::ReportLiveCheckBrokenJob)
          .with("Integrations::Unavailable: api.twitch.tv responded 503").once
      end

      context "when the check has failed for less than 24 hours" do
        let(:failing_for) { 20.hours }

        it "does not tell the owner yet" do
          expect { perform }.not_to have_enqueued_job(Integrations::Twitch::ReportLiveCheckBrokenJob)
        end
      end

      context "when the owner was already told today" do
        before do
          described_class.perform_now
        end

        it "does not tell them again" do
          expect { perform }.not_to have_enqueued_job(Integrations::Twitch::ReportLiveCheckBrokenJob)
        end
      end

      context "when a check succeeded in between" do
        let(:failing_for) { 12.hours }

        before do
          allow(streams).to receive(:live).and_return([stream])
          described_class.perform_now
          allow(streams).to receive(:live).and_raise(Integrations::Unavailable, "api.twitch.tv responded 503")
          travel 50.minutes
          described_class.perform_now
          4.times do
            travel 2.hours
            described_class.perform_now
          end
          travel 70.minutes
        end

        it "counts the 24 hours from the failure after it" do
          expect { perform }.not_to have_enqueued_job(Integrations::Twitch::ReportLiveCheckBrokenJob)
        end
      end

      context "when no check ran for longer than the dormant gap" do
        let(:failing_for) { 0.hours }

        before do
          travel 25.hours
        end

        it "does not count the old failure toward the 24 hours" do
          expect { perform }.not_to have_enqueued_job(Integrations::Twitch::ReportLiveCheckBrokenJob)
        end
      end
    end
  end

  context "when Twitch rate limits the request" do
    before do
      allow(streams).to receive(:live).and_raise(Integrations::RateLimited.new("slow down", retry_after: 30))
    end

    it "reports it to the owner once" do
      expect { perform }.to have_enqueued_job(Integrations::ReportRateLimitJob).with("Twitch streams", "slow down", 30).once
    end

    it "leaves every watch's health untouched" do
      perform

      expect(Integrations::Watch.where(watcher:)).to all(
        have_attributes(failing_since: nil, last_error: nil, polled_at: nil)
      )
    end

    context "when the next run is rate limited too" do
      before do
        described_class.perform_now
      end

      it "does not report it again within the day" do
        expect { perform }.not_to have_enqueued_job(Integrations::ReportRateLimitJob)
      end
    end
  end

  context "when Twitch rejects the app credentials" do
    before do
      allow(streams).to receive(:live).and_raise(Integrations::Unauthorized, "id.twitch.tv responded 400")
    end

    it "tells the owner at once, without waiting for the broken-watch report" do
      expect { perform }.to have_enqueued_job(Integrations::Twitch::ReportUnauthorizedJob).with("id.twitch.tv responded 400").once
    end

    context "when a timeout came between two rejections" do
      before do
        described_class.perform_now
        allow(streams).to receive(:live).and_raise(Integrations::Unavailable, "api.twitch.tv timed out")
        described_class.perform_now
        allow(streams).to receive(:live).and_raise(Integrations::Unauthorized, "id.twitch.tv responded 400")
      end

      it "does not tell them again within the day" do
        expect { perform }.not_to have_enqueued_job(Integrations::Twitch::ReportUnauthorizedJob)
      end
    end

    context "when the rejections have lasted 24 hours" do
      before do
        freeze_time
        described_class.perform_now
        11.times do
          travel 2.hours
          described_class.perform_now
        end
        travel 2.hours
      end

      it "sends no broken-check DM on top of the credentials DM" do
        expect { perform }.not_to have_enqueued_job(Integrations::Twitch::ReportLiveCheckBrokenJob)
      end
    end
  end

  context "when one watch's transition raises" do
    before do
      allow(Ops::Integrations::Twitch::Streams::Transition).to receive(:call).and_call_original
      allow(Ops::Integrations::Twitch::Streams::Transition).to receive(:call).with(hash_including(watch: live_watch)).and_raise(NoMethodError, "our bug")
    end

    let!(:idle_watch) { create(:integration_watch, watcher:, external_id: "2", name: "Idle Two", state: {"session" => "old", "stream_ids" => ["old"], "peak_viewers" => 1, "started_at" => "2026-11-01T08:00:00Z", "last_live_at" => 10.minutes.ago.iso8601, "login" => "idle", "display_name" => "Idle Two"}) }

    it "does not write the error onto the watch" do
      perform

      expect(live_watch.reload.last_error).to be_nil
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
