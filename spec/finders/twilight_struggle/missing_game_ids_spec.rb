# frozen_string_literal: true

require "rails_helper"

RSpec.describe Finders::TwilightStruggle::MissingGameIds do
  subject(:ids) { described_class.new(arrived_external_id).ids }

  let(:arrived_external_id) { "110" }

  context "when no other game exists" do
    it { is_expected.to eq([]) }
  end

  context "when the arrival follows the game before it" do
    let!(:previous) { create(:twilight_struggle_game, external_id: "109") }

    it { is_expected.to eq([]) }
  end

  context "when one game between them is missing" do
    let!(:previous) { create(:twilight_struggle_game, external_id: "108") }

    it { is_expected.to eq([109]) }
  end

  context "when several games between them are missing" do
    let!(:previous) { create(:twilight_struggle_game, external_id: "100") }

    it { is_expected.to eq((101..109).to_a) }
  end

  context "when the arrived row is already stored" do
    let!(:previous) { create(:twilight_struggle_game, external_id: "100") }
    let!(:arrived) { create(:twilight_struggle_game, external_id: arrived_external_id) }

    it "does not treat the arrival as the game before itself" do
      expect(ids).to eq((101..109).to_a)
    end
  end

  context "when a later game arrived before the check ran" do
    let!(:previous) { create(:twilight_struggle_game, external_id: "108") }
    let!(:later) { create(:twilight_struggle_game, external_id: "111") }

    it "still reports the gap below the arrival" do
      expect(ids).to eq([109])
    end
  end

  context "when the missing game arrived before the check ran" do
    let!(:previous) { create(:twilight_struggle_game, external_id: "108") }
    let!(:recovered) { create(:twilight_struggle_game, external_id: "109") }

    it { is_expected.to eq([]) }
  end

  context "when the arrival is below every stored game" do
    let(:arrived_external_id) { "50" }
    let!(:previous) { create(:twilight_struggle_game, external_id: "200") }

    it { is_expected.to eq([]) }
  end
end
