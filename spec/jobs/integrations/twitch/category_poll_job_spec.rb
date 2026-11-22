# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::CategoryPollJob do
  subject(:perform) { described_class.perform_now }

  let!(:chess) { create(:integration_watch, watcher: "Integrations::Twitch::CategoryWatcher", external_id: "7", name: "Chess") }
  let!(:go) { create(:integration_watch, watcher: "Integrations::Twitch::CategoryWatcher", external_id: "8", name: "Go") }
  let!(:channel) { create(:integration_watch, :twitch, external_id: "1", name: "Live One") }
  let(:followed) { [chess, go] }
  let(:streams) { instance_double(Integrations::Twitch::Streams) }
  let(:users) { instance_double(Integrations::Twitch::Users, for: []) }
  let(:chess_streams) { [stream("s1", "1", "7")] }
  let(:go_streams) { [stream("s2", "2", "8")] }

  def stream(id, user_id, category_id)
    Integrations::Twitch::Stream.new(
      id:,
      user_id:,
      user_login: "user#{user_id}",
      user_name: "User #{user_id}",
      category_id:,
      category_name: "Cat",
      title: "Ranked",
      viewer_count: 12,
      started_at: Time.zone.parse("2026-11-01 09:00:00"),
      language: "en"
    )
  end

  before do
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    allow(Integrations::Twitch::Client).to receive(:configured?).and_return(true)
    allow(Integrations::Twitch::Streams).to receive(:new).and_return(streams)
    allow(Integrations::Twitch::Users).to receive(:new).and_return(users)
    allow(Integrations::Twitch::CategoryWatcher).to receive(:followed) { Integrations::Watch.where(id: followed.map(&:id)) }
    allow(streams).to receive(:in_category).with("7").and_return(chess_streams)
    allow(streams).to receive(:in_category).with("8").and_return(go_streams)
    allow(users).to receive(:for).with(["2"]).and_return(
      [Integrations::Twitch::User.new(id: "2", login: "user2", display_name: "User 2", profile_image_url: "https://example.test/2.png")]
    )
  end

  context "when Twitch is not configured" do
    before do
      allow(Integrations::Twitch::Client).to receive(:configured?).and_return(false)
    end

    it "asks Twitch for nothing" do
      perform

      expect(streams).not_to have_received(:in_category)
    end
  end

  context "when no category is followed" do
    let(:followed) { [] }

    it "asks Twitch for nothing" do
      perform

      expect(streams).not_to have_received(:in_category)
    end
  end

  describe "concurrency" do
    it "gives every run the same key, so an overlapping run is discarded" do
      expect(described_class.new.concurrency_key).to eq(described_class.new.concurrency_key)
      expect(described_class).to have_attributes(concurrency_on_conflict: :discard)
    end
  end

  context "with streams in two categories" do
    before do
      allow(Ops::Integrations::Twitch::Streams::TransitionAll).to receive(:call).and_call_original
    end

    it "hands the sighting's observations, and only those, to the transition" do
      perform

      expect(Ops::Integrations::Twitch::Streams::TransitionAll).to have_received(:call) do |observations:|
        expect(observations.map { |watch, live| [watch.external_id, live.stream_id] }).to eq([%w[1 s1], %w[2 s2]])
      end
    end

    it "starts a session on the discovered channel watch" do
      perform

      expect(channel.reload.state).to include("session" => "s1")
      expect(Integrations::Watch.find_by!(external_id: "2").state).to include("session" => "s2")
    end

    context "when a stream's session is already open and unchanged" do
      before do
        described_class.perform_now
      end

      it "transitions nothing and writes no sample" do
        expect { perform }.not_to change(Integrations::Event, :count)
      end
    end
  end

  context "when a follow has a viewer floor and a stream climbs past it" do
    let(:chess_streams) { [stream("s1", "1", "7")] }
    let(:climbed) { [stream("s1", "1", "7").with(viewer_count: 30)] }

    before do
      create(:feed_subscription, :active, :twitch_category, watch: chess).settings.update!(min_viewers: 20)
      described_class.perform_now
      allow(streams).to receive(:in_category).with("7").and_return(climbed)
    end

    it "records a sample at the crossing" do
      expect { perform }.to change { Integrations::Twitch::StreamSampled.count }.by(1)
    end
  end

  context "when Twitch rate limits a category" do
    before do
      allow(streams).to receive(:in_category).with("7").and_raise(Integrations::RateLimited.new("slow down", retry_after: 30))
    end

    it "stops the tick and tells the owner once" do
      expect { perform }.to have_enqueued_job(Integrations::ReportRateLimitJob).with("Twitch categories", "slow down", 30).once
      expect(streams).not_to have_received(:in_category).with("8")
      expect(channel.reload.state).to eq({})
    end

    it "does not tell the owner again within the day" do
      described_class.perform_now

      expect { perform }.not_to have_enqueued_job(Integrations::ReportRateLimitJob)
    end
  end

  context "when one category fails" do
    before do
      allow(streams).to receive(:in_category).with("7").and_raise(Integrations::Unavailable, "api.twitch.tv responded 503")
    end

    it "still transitions the next category" do
      perform

      expect(Integrations::Watch.find_by!(external_id: "2").state).to include("session" => "s2")
    end

    it "records the failure on that category's watch only" do
      perform

      expect(chess.reload).to have_attributes(failing_since: be_present, last_error: "Integrations::Unavailable: api.twitch.tv responded 503")
      expect(go.reload).to have_attributes(failing_since: nil, last_error: nil)
    end

    it "does not count as a failed job-level check" do
      expect { perform }.not_to have_enqueued_job(Integrations::Twitch::ReportCategoryCheckBrokenJob)
      expect(Rails.cache.read("integrations/twitch/categories/failing_since")).to be_nil
    end

    context "when the category answers on a later tick" do
      before do
        described_class.perform_now
        allow(streams).to receive(:in_category).with("7").and_return(chess_streams)
      end

      it "clears the failure" do
        perform

        expect(chess.reload).to have_attributes(failing_since: nil, last_error: nil)
      end
    end
  end

  context "when every category fails" do
    before do
      allow(streams).to receive(:in_category).and_raise(Integrations::Unavailable, "api.twitch.tv responded 503")
    end

    it "records each watch and sends no job-level report" do
      expect { perform }.not_to have_enqueued_job(Integrations::Twitch::ReportCategoryCheckBrokenJob)
      expect(chess.reload.failing_since).to be_present
      expect(go.reload.failing_since).to be_present
    end
  end

  context "when looking up the broadcasters fails for 24 hours" do
    before do
      allow(users).to receive(:for).and_raise(Integrations::Unavailable, "api.twitch.tv responded 503")
      Rails.cache.write("integrations/twitch/categories/failing_since", 25.hours.ago, expires_in: 1.hour)
    end

    it "tells the owner once" do
      expect { perform }.to have_enqueued_job(Integrations::Twitch::ReportCategoryCheckBrokenJob)
        .with("Integrations::Unavailable: api.twitch.tv responded 503").once
    end
  end

  context "when Twitch rejects the app credentials" do
    before do
      allow(streams).to receive(:in_category).and_raise(Integrations::Unauthorized, "id.twitch.tv responded 400")
    end

    it "tells the owner at once" do
      expect { perform }.to have_enqueued_job(Integrations::Twitch::ReportUnauthorizedJob).with("id.twitch.tv responded 400").once
    end
  end

  context "when looking up the broadcasters fails" do
    before do
      allow(users).to receive(:for).and_raise(Integrations::Unavailable, "api.twitch.tv responded 503")
    end

    it "reports the failure without transitioning anything" do
      perform

      expect(channel.reload.state).to eq({})
    end
  end
end
