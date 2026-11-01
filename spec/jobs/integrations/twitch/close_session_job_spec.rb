# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::CloseSessionJob do
  subject(:perform) { described_class.perform_now(watch, offline_at.iso8601) }

  let(:offline_at) { Time.zone.parse("2026-11-01 11:00:00") }
  let(:watch) do
    create(
      :integration_watch,
      watcher: "Integrations::Twitch::ChannelWatcher",
      state: {
        "session" => "s1",
        "stream_ids" => ["s1"],
        "peak_viewers" => 3,
        "started_at" => "2026-11-01T09:00:00Z",
        "login" => "shroud",
        "display_name" => "Shroud",
        "offline_at" => offline_at.iso8601
      }
    )
  end

  it "closes the session that went offline at that time" do
    perform

    expect(watch.reload.state).to eq("login" => "shroud", "display_name" => "Shroud")
    expect(watch.events).to contain_exactly(an_instance_of(Integrations::Twitch::StreamEnded))
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
