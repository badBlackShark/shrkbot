# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReleaseInfo do
  describe ".current" do
    subject(:release) { described_class.current }

    before { described_class.instance_variable_set(:@current, nil) }

    context "with released and unreleased sections in the changelog" do
      let(:changelog) do
        <<~MD
          ## [Unreleased]
          ### Fixed
          - pending stuff
          ## [3.1.0] - 2026-07-11
          ### Added
          - shipped stuff
        MD
      end

      before do
        allow(described_class::CHANGELOG).to receive_messages(exist?: true, read: changelog)
      end

      it "reads the latest released version, skipping Unreleased" do
        expect(release.number).to eq("3.1.0")
      end

      it "reads the release date" do
        expect(release.released_on).to eq(Date.new(2026, 7, 11))
      end
    end

    context "with no released entry" do
      before do
        allow(described_class::CHANGELOG).to receive_messages(exist?: true, read: "## [Unreleased]\n- nothing yet\n")
      end

      it "returns nil" do
        expect(release).to be_nil
      end
    end

    context "when the changelog is missing" do
      before { allow(described_class::CHANGELOG).to receive(:exist?).and_return(false) }

      it "returns nil" do
        expect(release).to be_nil
      end
    end
  end

  describe "#release_url" do
    subject(:release) { described_class.new(number: "3.1.0", released_on: Date.new(2026, 7, 11)) }

    it "links to the GitHub release tag" do
      expect(release.release_url).to eq("https://github.com/badBlackShark/shrkbot/releases/tag/3.1.0")
    end
  end
end
