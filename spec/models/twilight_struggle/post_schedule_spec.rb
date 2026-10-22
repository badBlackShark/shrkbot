# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwilightStruggle::PostSchedule do
  include ActiveSupport::Testing::TimeHelpers

  subject(:wait) { described_class.new(game:, server_configuration:, reported_at:).wait }

  let(:server_configuration) { create(:server_configuration) }
  let(:tournament) { create(:twilight_struggle_tournament) }
  let(:game) { create(:twilight_struggle_game, tournament:) }
  let(:post_delay_seconds) { nil }
  let(:reported_at) { Time.current }

  before do
    freeze_time
    create(:twilight_struggle_destination, tournament:, server_configuration:, post_delay_seconds:)
  end

  context "when the server sets no delay" do
    it "does not wait" do
      expect(wait).to eq(0)
    end
  end

  context "when the server sets a delay and the result was reported just now" do
    let(:post_delay_seconds) { 900 }

    it "waits the full delay" do
      expect(wait).to eq(900)
    end
  end

  context "when the result was reported longer ago than the delay" do
    let(:post_delay_seconds) { 900 }
    let(:reported_at) { 20.minutes.ago }

    it "does not wait" do
      expect(wait).to eq(0)
    end
  end

  context "when the result was reported part-way through the delay" do
    let(:post_delay_seconds) { 900 }
    let(:reported_at) { 5.minutes.ago }

    it "waits only the remainder" do
      expect(wait).to eq(600)
    end
  end

  context "when the reported time lies in the future" do
    let(:post_delay_seconds) { 900 }
    let(:reported_at) { 5.hours.from_now }

    it "waits no longer than the delay" do
      expect(wait).to eq(900)
    end

    context "when the job runs again once the delay is up" do
      let!(:game) { create(:twilight_struggle_game, tournament:) }

      before { travel 900.seconds }

      it "no longer waits" do
        expect(wait).to eq(0)
      end
    end
  end

  context "when the result is already posted to this server" do
    let(:post_delay_seconds) { 900 }

    before { create(:twilight_struggle_posted_message, game:, server_configuration:) }

    it "does not delay the edit" do
      expect(wait).to eq(0)
    end
  end

  context "when the result is posted to a different server only" do
    let(:post_delay_seconds) { 900 }

    before { create(:twilight_struggle_posted_message, game:) }

    it "still waits for this server" do
      expect(wait).to eq(900)
    end
  end

  context "when the delay comes from a parent tournament" do
    let(:parent) { create(:twilight_struggle_tournament) }
    let(:tournament) { create(:twilight_struggle_tournament, parent:) }

    before { create(:twilight_struggle_destination, tournament: parent, server_configuration:, post_delay_seconds: 600) }

    it "uses the inherited delay" do
      expect(wait).to eq(600)
    end
  end
end
