# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::CategorySighting do
  subject(:observations) { described_class.new(streams: [stream], watches: {"1" => watch}).observations }

  let(:watch) { build(:integration_watch, :twitch, external_id: "1", state:) }
  let(:state) { open_state }
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
  let(:open_state) do
    {
      "session" => "s1",
      "stream_ids" => ["s1"],
      "title" => "Ranked",
      "category_id" => "7",
      "language" => "en"
    }
  end

  context "when the watch has no open session" do
    let(:state) { {} }

    it "transitions it with the stream as a Live observation" do
      expect(observations).to eq([[watch, Integrations::Twitch::Live.from_stream(stream)]])
    end
  end

  context "when the stream id is new to the open session" do
    let(:state) { open_state.merge("stream_ids" => ["s0"]) }

    it "transitions it, so a reconnect is merged" do
      expect(observations).to eq([[watch, Integrations::Twitch::Live.from_stream(stream)]])
    end
  end

  context "when the stream is already in the open session and nothing changed" do
    it "skips it, so the minute poll writes no sample per stream" do
      expect(observations).to be_empty
    end
  end

  {
    "title" => {"title" => "Casual"},
    "category" => {"category_id" => "8"},
    "language" => {"language" => "de"}
  }.each do |name, change|
    context "when the #{name} differs from the open session" do
      let(:state) { open_state.merge(change) }

      it "transitions it" do
        expect(observations.map(&:first)).to eq([watch])
      end

      context "when titles are pushed" do
        let(:state) { super().merge("titles_pushed" => true) }

        it "skips it, because push owns them" do
          expect(observations).to be_empty
        end
      end
    end
  end

  describe "viewer floors" do
    subject(:observations) { described_class.new(streams: [stream], watches: {"1" => watch}, floors:).observations }

    let(:floors) { {"7" => [10, 50]} }
    let(:state) { open_state.merge("viewer_count" => stored) }
    let(:stored) { 9 }

    context "when the count rose across a floor since the stored sample" do
      it "transitions it" do
        expect(observations.map(&:first)).to eq([watch])
      end
    end

    context "when the stored count was already past the floor" do
      let(:stored) { 10 }

      it "skips it" do
        expect(observations).to be_empty
      end
    end

    context "when no count was stored" do
      let(:state) { open_state }

      it "counts it as zero" do
        expect(observations.map(&:first)).to eq([watch])
      end
    end

    context "when the count is still below every floor" do
      let(:floors) { {"7" => [13]} }

      it "skips it" do
        expect(observations).to be_empty
      end
    end

    context "when the floors belong to another category" do
      let(:floors) { {"8" => [10]} }

      it "skips it" do
        expect(observations).to be_empty
      end
    end
  end

  context "when the stream's watch is missing" do
    subject(:observations) { described_class.new(streams: [stream], watches: {}).observations }

    it "skips it" do
      expect(observations).to be_empty
    end
  end
end
