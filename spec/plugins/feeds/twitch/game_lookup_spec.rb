# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Twitch::GameLookup do
  include ActiveSupport::Testing::TimeHelpers

  subject(:result) { described_class.find(category_id) }

  let(:category_id) { "1145360737" }
  let(:games) { instance_double(Integrations::Twitch::Games) }
  let(:game) { Integrations::Twitch::Game.new(id: category_id, name: "Hades II", box_art_url: "https://cdn.test/box.jpg") }

  before do
    freeze_time
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    allow(Integrations::Twitch::Games).to receive(:new).and_return(games)
    allow(games).to receive(:find).with("1145360737").and_return(game)
  end

  it "is the game" do
    expect(result).to eq(game)
  end

  it "caches plain attributes, so a Game that gains a member still reads entries cached before" do
    result

    expect(Rails.cache.read(["feeds/twitch/game/v1", category_id])).to eq(game.to_h)
  end

  it "looks the game up once for repeated calls" do
    2.times { described_class.find(category_id) }

    expect(games).to have_received(:find).once
  end

  context "without a category id" do
    let(:category_id) { nil }

    it "is nil without a lookup" do
      expect(result).to be_nil
      expect(games).not_to have_received(:find)
    end
  end

  context "when the lookup fails" do
    before do
      allow(games).to receive(:find).and_raise(Integrations::Unavailable)
    end

    it "is nil" do
      expect(result).to be_nil
    end

    it "does not retry within ten minutes but does after" do
      described_class.find(category_id)

      travel_to(9.minutes.from_now) do
        described_class.find(category_id)
      end

      expect(games).to have_received(:find).once

      travel_to(11.minutes.from_now) do
        described_class.find(category_id)
      end

      expect(games).to have_received(:find).twice
    end
  end
end
