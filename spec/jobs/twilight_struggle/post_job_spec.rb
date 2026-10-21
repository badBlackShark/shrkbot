# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe TwilightStruggle::PostJob do
  include ActiveSupport::Testing::TimeHelpers

  subject(:perform) { described_class.perform_now(game, server_configuration, payload, revision) }

  let(:game) { create(:twilight_struggle_game) }
  let(:server_configuration) { create(:server_configuration) }
  let(:revision) { 3 }
  let(:reported_at) { Time.utc(2026, 7, 24, 10) }
  let(:payload) do
    {
      "reported_at" => reported_at.iso8601,
      "game_code" => "R1",
      "game_date" => "2026-07-20",
      "winning_side" => "usa",
      "winning_turn" => 6,
      "winning_method" => "Objectives",
      "usa" => {"name" => "Alice", "country_code" => "US"},
      "ussr" => {"name" => "Bob", "country_code" => "RU"},
      "video_urls" => ["https://example.com/video"]
    }
  end
  let(:report) { instance_double(TwilightStruggle::GameReport, reported_at:) }

  before do
    travel_to reported_at
    allow(TwilightStruggle::GameReport).to receive(:from_payload).with(payload).and_return(report)
    allow(Ops::TwilightStruggle::Games::Post).to receive(:call).and_return(
      Ops::ApplicationOperation::Result.new(true, game, [], [])
    )
  end

  it "builds the report from the payload" do
    perform

    expect(TwilightStruggle::GameReport).to have_received(:from_payload).with(payload)
  end

  it "calls the post operation with the game, server, and built report" do
    perform

    expect(Ops::TwilightStruggle::Games::Post).to have_received(:call).with(game:, server_configuration:, report:)
  end

  context "when a newer version of the game arrived after this job was queued" do
    let(:game) { create(:twilight_struggle_game, revision: revision + 1) }

    it "does not post" do
      perform

      expect(Ops::TwilightStruggle::Games::Post).not_to have_received(:call)
    end

    context "when the server delays posting" do
      before do
        create(:twilight_struggle_destination, tournament: game.tournament, server_configuration:, post_delay_seconds: 900)
      end

      it "drops the job instead of waiting out the delay with the old details" do
        expect { perform }.not_to have_enqueued_job(described_class)
      end
    end
  end

  context "when the result is already posted to this server" do
    before do
      create(:twilight_struggle_destination, tournament: game.tournament, server_configuration:, post_delay_seconds: 900)
      create(:twilight_struggle_posted_message, game:, server_configuration:)
    end

    it "edits it without waiting for the delay" do
      perform

      expect(Ops::TwilightStruggle::Games::Post).to have_received(:call).with(game:, server_configuration:, report:)
    end
  end

  context "when the server delays posting and the result was just reported" do
    let!(:destination) do
      create(:twilight_struggle_destination, tournament: game.tournament, server_configuration:, post_delay_seconds: 900)
    end

    it "does not post yet" do
      perform

      expect(Ops::TwilightStruggle::Games::Post).not_to have_received(:call)
    end

    it "queues itself for when the delay is up, with the same arguments" do
      expect { perform }.to have_enqueued_job(described_class)
        .with(game, server_configuration, payload, revision)
        .at(a_value_within(1.second).of(reported_at + 900.seconds))
    end
  end

  context "when the run is logged" do
    let(:log) { StringIO.new }

    before do
      allow(ActiveJob::Base).to receive(:logger).and_return(ActiveSupport::Logger.new(log))
    end

    it "logs the job without the result details" do
      perform

      expect(log.string).to include("Performing TwilightStruggle::PostJob")
      expect(log.string).not_to include("Alice")
    end
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
