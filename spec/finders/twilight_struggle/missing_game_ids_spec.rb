# frozen_string_literal: true

require "rails_helper"

RSpec.describe Finders::TwilightStruggle::MissingGameIds do
  subject(:ids) { described_class.new(candidate_ids).ids }

  let(:candidate_ids) { [101, 102, 103] }

  context "when none of the candidates are stored" do
    it { is_expected.to eq([101, 102, 103]) }
  end

  context "when some candidates are stored and some are not" do
    let!(:stored) { create(:twilight_struggle_game, external_id: "102") }

    it { is_expected.to eq([101, 103]) }
  end

  context "when every candidate is stored" do
    let!(:first) { create(:twilight_struggle_game, external_id: "101") }
    let!(:second) { create(:twilight_struggle_game, external_id: "102") }
    let!(:third) { create(:twilight_struggle_game, external_id: "103") }

    it { is_expected.to eq([]) }
  end

  context "when given no candidates" do
    let(:candidate_ids) { [] }

    it { is_expected.to eq([]) }
  end
end
