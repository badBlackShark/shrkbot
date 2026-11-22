# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::CategoryStreams do
  let(:category_streams) { described_class.new(streams:) }
  let(:streams) { instance_double(Integrations::Twitch::Streams, in_category: [stream]) }
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
      language: "en"
    )
  end

  before do
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
  end

  describe "#refresh" do
    subject(:refreshed) { category_streams.refresh("7") }

    it "fetches the page and returns it" do
      expect(refreshed).to eq([stream])
    end

    it "caches it for #current" do
      refreshed

      expect(category_streams.current("7")).to eq([stream])
      expect(streams).to have_received(:in_category).once
    end
  end

  describe "#current" do
    it "fetches when nothing is cached" do
      expect(category_streams.current("7")).to eq([stream])
      expect(streams).to have_received(:in_category).with("7")
    end
  end
end
