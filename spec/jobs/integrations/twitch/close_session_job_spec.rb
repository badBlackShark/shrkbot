# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::CloseSessionJob do
  subject(:perform) { described_class.perform_now(watch, offline_at.iso8601) }

  let(:offline_at) { 5.minutes.ago.change(usec: 0) }
  let(:watch) do
    create(
      :integration_watch,
      watcher: "Integrations::Twitch::ChannelWatcher",
      external_id: "99",
      state: {
        "session" => "s1",
        "stream_ids" => ["s1"],
        "peak_viewers" => 3,
        "started_at" => 3.hours.ago.iso8601,
        "last_live_at" => 15.minutes.ago.iso8601,
        "login" => "shroud",
        "display_name" => "Shroud",
        "offline_at" => offline_at.iso8601
      }
    )
  end
  let(:streams) { instance_double(Integrations::Twitch::Streams, live: []) }

  before do
    allow(Integrations::Twitch::Streams).to receive(:new).and_return(streams)
  end

  it "asks Twitch about this channel once" do
    perform

    expect(streams).to have_received(:live).with(["99"])
  end

  context "when the channel is still offline" do
    it "closes the session that went offline at that time" do
      perform

      expect(watch.reload.state).to eq("login" => "shroud", "display_name" => "Shroud")
      expect(watch.events).to contain_exactly(an_instance_of(Integrations::Twitch::StreamEnded))
    end
  end

  context "when the channel came back with a new stream inside the grace period" do
    let(:streams) do
      instance_double(
        Integrations::Twitch::Streams,
        live: [
          Integrations::Twitch::Stream.new(
            id: "s2",
            user_id: "99",
            user_login: "shroud",
            user_name: "Shroud",
            category_id: nil,
            category_name: nil,
            title: nil,
            viewer_count: 3,
            started_at: 1.minute.ago,
            thumbnail_url: "https://example.test/t.jpg"
          )
        ]
      )
    end

    it "keeps the session, so a reconnect never ends it" do
      perform

      expect(watch.reload.state).to include("session" => "s1", "stream_ids" => %w[s1 s2])
      expect(watch.reload.state).not_to have_key("offline_at")
      expect(watch.events.where(type: "Integrations::Twitch::StreamEnded")).to be_empty
    end
  end

  context "when Twitch is unavailable" do
    before do
      allow(streams).to receive(:live).and_raise(Integrations::Unavailable, "api.twitch.tv responded 503")
      allow(Rails.logger).to receive(:warn)
    end

    it "leaves the session open for a later reconcile" do
      perform

      expect(watch.reload.state).to include("session" => "s1")
      expect(Rails.logger).to have_received(:warn).with(/close check for .* failed/)
    end
  end

  context "when the watch is deleted before the job runs" do
    let(:payload) { described_class.new(watch, offline_at.iso8601).serialize }

    before do
      payload
      watch.destroy!
    end

    it "is discarded instead of failing" do
      expect { ActiveJob::Base.execute(payload) }.not_to raise_error
    end
  end
end
