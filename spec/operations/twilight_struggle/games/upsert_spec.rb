# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::TwilightStruggle::Games::Upsert do
  subject(:result) { described_class.call(external_id:, tournament:, payload:) }

  let(:external_id) { "ext-game-1" }
  let(:tournament) { create(:twilight_struggle_tournament) }
  let(:payload) { {"winning_side" => "usa"} }

  it "creates a game when none exists" do
    expect { result }.to change(TwilightStruggle::Game, :count).by(1)
  end

  it "attaches the game to the given tournament" do
    expect(result.value.tournament).to eq(tournament)
  end

  it "enqueues the post job with the saved game and the payload" do
    expect { result }.to have_enqueued_job(TwilightStruggle::PostJob).with(
      an_object_having_attributes(external_id:),
      payload
    )
  end

  context "with a blank external_id" do
    let(:external_id) { "" }

    it "returns a failure with the validation errors" do
      expect(result).to be_failure
      expect(result.errors).to be_present
    end

    it "does not enqueue a post job" do
      expect { result }.not_to have_enqueued_job(TwilightStruggle::PostJob)
    end
  end

  context "when a game with the external_id already exists" do
    let!(:existing) { create(:twilight_struggle_game, external_id:) }

    it "updates the row in place" do
      expect { result }.not_to change(TwilightStruggle::Game, :count)
      expect(existing.reload.tournament).to eq(tournament)
    end
  end

  context "when no tournament is passed" do
    let(:tournament) { nil }

    it "attaches to the friendly tournament, creating it on first use" do
      expect { result }.to change { TwilightStruggle::Tournament.where(friendly: true).count }.by(1)
      expect(result.value.tournament.friendly).to be(true)
    end

    context "when a friendly game already exists" do
      before { described_class.call(external_id: "ext-game-0", tournament: nil, payload:) }

      it "reuses the same friendly tournament" do
        result
        expect(TwilightStruggle::Tournament.where(friendly: true).count).to eq(1)
      end
    end

    context "when a concurrent request creates the friendly tournament first" do
      let!(:concurrent) { create(:twilight_struggle_tournament, :friendly) }

      before do
        allow(TwilightStruggle::Tournament).to receive(:find_by).and_call_original
        allow(TwilightStruggle::Tournament).to receive(:find_by).with(friendly: true).and_return(nil, concurrent)
        allow(TwilightStruggle::Tournament).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique)
      end

      it "recovers by reading the winner of the race" do
        expect(result.value.tournament).to eq(concurrent)
      end
    end
  end
end
