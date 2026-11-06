# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Twitch::Vod do
  subject(:url) { described_class.url_for(event) }

  let(:event) { instance_double(Integrations::Twitch::StreamEnded, session: "40000000001", stream_ids: ["40000000001"], watch:) }
  let(:watch) { instance_double(Integrations::Watch, watcher_class:, external_id: "141981764") }
  let(:watcher_class) { class_double(Integrations::Twitch::ChannelWatcher) }
  let(:vod_url) { "https://www.twitch.tv/videos/1" }

  before do
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    allow(watcher_class).to receive(:vod_url).with("141981764", ["40000000001"]).and_return(vod_url)
  end

  it "is the watcher's VOD URL" do
    expect(url).to eq(vod_url)
  end

  it "asks once per session" do
    2.times { described_class.url_for(event) }

    expect(watcher_class).to have_received(:vod_url).once
  end

  context "when Twitch is unavailable" do
    before do
      allow(watcher_class).to receive(:vod_url).and_raise(Integrations::Unavailable)
    end

    it "raises and caches nothing, so the next call asks again" do
      2.times { expect { described_class.url_for(event) }.to raise_error(Integrations::Unavailable) }

      expect(watcher_class).to have_received(:vod_url).twice
    end
  end
end
