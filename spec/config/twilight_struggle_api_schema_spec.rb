# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwilightStruggleApiSchema do
  describe ".document" do
    subject(:document) { described_class.document }

    let(:operations) { document["paths"].values.flat_map { |path| path.slice("put", "delete").values } }

    it "states the base URL in the overview, not only in the servers block" do
      expect(document.dig("info", "description")).to include("https://shrkbot.com/api/twilight-struggle/v1")
    end

    it "introduces the resources in the order they have to be sent in" do
      expect(document["tags"].map { |tag| tag["name"] }).to eq(["Tournaments", "Games"])
    end

    it "describes every resource" do
      expect(document["tags"]).to all(include("description" => a_string_matching(/\S/)))
    end

    it "files every operation under a declared resource" do
      expect(operations.flat_map { |operation| operation["tags"] }.uniq).to match_array(described_class::TAGS)
    end
  end

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
