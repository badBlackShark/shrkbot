# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecurityUpdates::Audit do
  describe ".gems" do
    subject(:advisories) { described_class.gems(report) }

    let(:report) { {"results" => [result]} }

    context "with an unpatched gem" do
      let(:result) do
        {
          "type" => "unpatched_gem",
          "gem" => {"name" => "rack", "version" => "3.0.0"},
          "advisory" => {
            "id" => "CVE-2026-1",
            "title" => "Bad thing",
            "url" => "https://example.test/CVE-2026-1",
            "patched_versions" => ["~> 3.1", ">= 3.2"]
          }
        }
      end

      it "maps every field" do
        expect(advisories).to eq(
          [
            SecurityUpdates::Advisory.new(
              package: "rack",
              version: "3.0.0",
              id: "CVE-2026-1",
              title: "Bad thing",
              url: "https://example.test/CVE-2026-1",
              fixed_in: ["~> 3.1", ">= 3.2"]
            )
          ]
        )
      end
    end

    context "with an insecure source" do
      let(:result) { {"type" => "insecure_source", "source" => "http://rubygems.org/"} }

      it "maps it to an advisory without a fixed version" do
        expect(advisories).to eq(
          [
            SecurityUpdates::Advisory.new(
              package: "http://rubygems.org/",
              version: nil,
              id: "insecure-source",
              title: "Gem source uses an insecure protocol",
              url: nil,
              fixed_in: []
            )
          ]
        )
      end
    end
  end

  describe ".pins" do
    subject(:advisories) { described_class.pins([package]) }

    let(:package) do
      Struct.new(:name, :severity, :vulnerable_versions, :vulnerability).new("tom-select", "high", "<2.6.2", "XSS")
    end

    it "maps a vulnerable pin to an advisory fixed by the latest version" do
      expect(advisories).to eq(
        [
          SecurityUpdates::Advisory.new(
            package: "tom-select",
            version: "<2.6.2",
            id: "high",
            title: "XSS",
            url: nil,
            fixed_in: ["latest"]
          )
        ]
      )
    end
  end
end
