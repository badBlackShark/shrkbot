# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::NotificationJob do
  subject(:perform) { described_class.perform_now(type, event) }

  let(:watcher) { "Integrations::Twitch::ChannelWatcher" }
  let(:state) { {} }
  let!(:watch) { create(:integration_watch, watcher:, external_id: "1", name: "Live One", state:) }
  let(:type) { "stream.online" }
  let(:event) do
    {
      "id" => "s1",
      "broadcaster_user_id" => "1",
      "broadcaster_user_login" => "liveone",
      "broadcaster_user_name" => "Live One",
      "type" => "live",
      "started_at" => "2026-11-01T09:00:00.5Z"
    }
  end
  let(:channels) { instance_double(Integrations::Twitch::Channels, for: [channel]) }
  let(:channel) { Integrations::Twitch::Channel.new(broadcaster_id: "1", title: "Ranked", category_id: "7", category_name: "Chess") }
  let(:open_state) do
    {
      "session" => "s1",
      "stream_ids" => ["s1"],
      "title" => "Ranked",
      "category_id" => "7",
      "category_name" => "Chess",
      "started_at" => "2026-11-01T09:00:00Z",
      "last_live_at" => 1.minute.ago.iso8601,
      "login" => "liveone",
      "display_name" => "Live One",
      "peak_viewers" => 5
    }
  end

  let(:demanded) { [watch] }

  before do
    allow(Integrations::Twitch::Channels).to receive(:new).and_return(channels)
    allow(Integrations::Twitch::ChannelWatcher).to receive(:followed_for_live) { Integrations::Watch.where(id: demanded.map(&:id)) }
  end

  context "when nobody follows the channel any more" do
    let(:demanded) { [] }

    it "leaves the watch alone" do
      perform

      expect(watch.reload.state).to eq({})
      expect(channels).not_to have_received(:for)
    end
  end

  context "when a stream goes online" do
    it "starts a session from the event and the channel's title, with no viewers yet" do
      perform

      expect(watch.reload.state).to include("session" => "s1", "title" => "Ranked", "category_name" => "Chess", "viewer_count" => nil, "peak_viewers" => nil, "login" => "liveone")
      expect(watch.events).to contain_exactly(an_instance_of(Integrations::Twitch::StreamStarted))
      expect(channels).to have_received(:for).with(["1"])
    end

    context "when the channel is missing from the lookup" do
      let(:channels) { instance_double(Integrations::Twitch::Channels, for: []) }

      it "leaves the state alone" do
        perform

        expect(watch.reload.state).to eq({})
      end
    end

    context "when Twitch is unavailable" do
      before do
        allow(channels).to receive(:for).and_raise(Integrations::Unavailable, "api.twitch.tv responded 503")
        allow(Rails.logger).to receive(:warn)
      end

      it "logs and leaves the state for the reconcile" do
        perform

        expect(watch.reload.state).to eq({})
        expect(Rails.logger).to have_received(:warn).with(/stream.online for channel 1 failed.*Integrations::Unavailable/)
      end
    end
  end

  context "when a stream goes offline in an open session" do
    let(:type) { "stream.offline" }
    let(:event) { {"broadcaster_user_id" => "1", "broadcaster_user_login" => "liveone", "broadcaster_user_name" => "Live One"} }
    let(:state) { open_state }

    it "marks it offline and schedules the close check" do
      expect { perform }.to have_enqueued_job(Integrations::Twitch::CloseSessionJob).once

      expect(watch.reload.state).to include("offline_at" => be_present)
    end
  end

  context "when the channel info changes in an open session" do
    let(:type) { "channel.update" }
    let(:event) { {"broadcaster_user_id" => "1", "title" => "Casual", "category_id" => "", "category_name" => ""} }
    let(:state) { open_state }

    it "records the new title and category" do
      perform

      expect(watch.reload.state).to include("title" => "Casual", "category_id" => nil, "category_name" => nil)
      expect(watch.events).to contain_exactly(an_instance_of(Integrations::Twitch::StreamUpdated))
    end
  end

  context "when nobody watches the broadcaster" do
    let(:event) { super().merge("broadcaster_user_id" => "999") }

    it "does nothing" do
      perform

      expect(channels).not_to have_received(:for)
      expect(Integrations::Event.count).to eq(0)
    end
  end

  context "with an unknown type" do
    let(:type) { "channel.follow" }

    it "does nothing" do
      perform

      expect(watch.reload.state).to eq({})
    end
  end
end
