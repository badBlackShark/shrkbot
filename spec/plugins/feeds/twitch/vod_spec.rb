# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Twitch::Vod do
  subject(:url) { described_class.url_for(event) }

  let(:event) { instance_double(Integrations::Twitch::StreamEnded, session: "40000000001", stream_ids:, watch:) }
  let(:watch) { instance_double(Integrations::Watch, external_id: "141981764") }
  let(:stream_ids) { %w[s1 s2] }
  let(:videos) { instance_double(Integrations::Twitch::Videos) }
  let(:blank_video) { Integrations::Twitch::Video.members.index_with(nil) }
  let(:archives) do
    %w[s2 s9 s1].map do |stream_id|
      Integrations::Twitch::Video.new(**blank_video, stream_id:, url: "https://www.twitch.tv/videos/v-#{stream_id}")
    end
  end

  before do
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    allow(Integrations::Twitch::Videos).to receive(:new).and_return(videos)
    allow(videos).to receive(:for_user).and_return(archives)
  end

  it "is the URL of the archive of the first stream id that has one" do
    expect(url).to eq("https://www.twitch.tv/videos/v-s1")
  end

  it "asks for the channel's archives" do
    url

    expect(videos).to have_received(:for_user).with("141981764", type: "archive", first: 20)
  end

  it "asks once per session" do
    2.times { described_class.url_for(event) }

    expect(videos).to have_received(:for_user).once
  end

  context "when no archive matches" do
    let(:stream_ids) { ["s7"] }

    it { is_expected.to be_nil }
  end

  context "when Twitch is unavailable" do
    before do
      allow(videos).to receive(:for_user).and_raise(Integrations::Unavailable)
    end

    it "raises and caches nothing, so the next call asks again" do
      2.times { expect { described_class.url_for(event) }.to raise_error(Integrations::Unavailable) }

      expect(videos).to have_received(:for_user).twice
    end
  end
end
