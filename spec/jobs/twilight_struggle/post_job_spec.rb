# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe TwilightStruggle::PostJob do
  subject(:perform) { described_class.perform_now(game, payload) }

  let(:game) { create(:twilight_struggle_game) }
  let(:payload) do
    {
      "game_code" => "R1",
      "game_date" => "2026-07-20",
      "winning_side" => "usa",
      "winning_turn" => 6,
      "winning_method" => "Objectives",
      "usa" => {"name" => "Alice", "flag" => "🇺🇸"},
      "ussr" => {"name" => "Bob", "flag" => "🇷🇺"},
      "video_urls" => ["https://example.com/video"]
    }
  end
  let(:report) { instance_double(TwilightStruggle::GameReport) }

  before do
    allow(TwilightStruggle::GameReport).to receive(:from_payload).with(payload).and_return(report)
    allow(Ops::TwilightStruggle::Games::Post).to receive(:call).and_return(
      Ops::ApplicationOperation::Result.new(true, game, [], [])
    )
  end

  it "builds the report from the payload" do
    perform

    expect(TwilightStruggle::GameReport).to have_received(:from_payload).with(payload)
  end

  it "calls the post operation with the game and the built report" do
    perform

    expect(Ops::TwilightStruggle::Games::Post).to have_received(:call).with(game:, report:)
  end

  context "when the destination channel is gone" do
    before do
      allow(Ops::TwilightStruggle::Games::Post).to receive(:call).and_raise(Discordrb::Errors::UnknownChannel.new("gone"))
    end

    it "discards instead of retrying" do
      expect { perform }.not_to raise_error
    end
  end

  context "when the bot lacks permission in the channel" do
    before do
      allow(Ops::TwilightStruggle::Games::Post).to receive(:call).and_raise(Discordrb::Errors::NoPermission.new("nope"))
    end

    it "discards instead of retrying" do
      expect { perform }.not_to raise_error
    end
  end
end
