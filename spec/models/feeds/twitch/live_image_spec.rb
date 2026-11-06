# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Twitch::LiveImage do
  include ActiveSupport::Testing::TimeHelpers

  subject(:result) { described_class.for(event) }

  let(:category_id) { "1145360737" }
  let(:event) { instance_double(Integrations::Twitch::StreamStarted, session: "40000000001", login: "shrkbot_dev", category_id:) }
  let(:previews) { instance_double(Integrations::Twitch::Previews) }
  let(:games) { instance_double(Integrations::Twitch::Games) }
  let(:preview) { "https://cdn.test/live_user_shrkbot_dev-1280x720.jpg" }
  let(:box_art) { "https://cdn.test/box.jpg" }
  let(:game) { Integrations::Twitch::Game.new(id: category_id, name: "Hades II", box_art_url: box_art) }

  before do
    freeze_time
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    allow(Integrations::Twitch::Previews).to receive(:new).and_return(previews)
    allow(previews).to receive(:url_for).with("shrkbot_dev").and_return(preview)
    allow(Integrations::Twitch::Games).to receive(:new).and_return(games)
    allow(games).to receive(:find).with("1145360737").and_return(game)
  end

  it "is the preview with a cache-busting timestamp, without looking up box art" do
    expect(result).to eq("#{preview}?t=#{Time.current.to_i}")
    expect(games).not_to have_received(:find)
  end

  it "checks the preview once a minute per stream, so every server gets the same URL" do
    first = described_class.for(event)
    travel 59.seconds
    second = described_class.for(event)
    travel 2.seconds
    described_class.for(event)

    expect(second).to eq(first)
    expect(previews).to have_received(:url_for).twice
  end

  context "when the preview is not ready" do
    let(:preview) { nil }

    it "is the category box art" do
      expect(result).to eq(box_art)
    end

    it "looks the box art up once for repeated calls" do
      2.times { described_class.for(event) }

      expect(games).to have_received(:find).once
    end

    context "when Twitch has no such category" do
      let(:game) { nil }

      it "is nil" do
        expect(result).to be_nil
      end
    end

    context "when the channel has no category" do
      let(:category_id) { nil }

      it "is nil without a box art lookup" do
        expect(result).to be_nil
        expect(games).not_to have_received(:find)
      end
    end

    context "when the box art lookup fails" do
      before do
        allow(games).to receive(:find).and_raise(Integrations::Unavailable)
      end

      it "is nil" do
        expect(result).to be_nil
      end

      it "does not retry within ten minutes but does after" do
        described_class.for(event)

        travel_to(9.minutes.from_now) do
          described_class.for(event)
        end

        expect(games).to have_received(:find).once

        travel_to(11.minutes.from_now) do
          described_class.for(event)
        end

        expect(games).to have_received(:find).twice
      end
    end
  end

  context "when the preview check fails" do
    before do
      allow(previews).to receive(:url_for).and_raise(Integrations::Unavailable)
    end

    it "falls back to the box art" do
      expect(result).to eq(box_art)
    end
  end
end
