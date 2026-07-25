# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwilightStruggleApiSchema do
  describe ".merge_disjoint!" do
    subject(:merge) { described_class.merge_disjoint!(into, from, "games.yaml") }

    let(:into) { {"/tournaments" => {}} }

    context "with disjoint keys" do
      let(:from) { {"/games" => {}} }

      it "adds them to the target" do
        merge

        expect(into).to eq({"/tournaments" => {}, "/games" => {}})
      end
    end

    context "with a key already present" do
      let(:from) { {"/tournaments" => {}} }

      it "raises rather than silently overwriting" do
        expect { merge }.to raise_error(/already defined by another schema fragment/)
      end
    end
  end
end
