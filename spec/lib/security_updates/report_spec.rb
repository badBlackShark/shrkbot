# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecurityUpdates::Report do
  subject(:markdown) { described_class.new(found:, remaining:, changes:).to_markdown }

  let(:changes) { [] }
  let(:remaining) { [] }
  let(:rack) { advisory(package: "rack", id: "CVE-1", version: "3.0.0") }
  let(:found) { [rack] }

  def advisory(package:, id:, version: "1.0.0", fixed_in: ["~> 3.1"])
    SecurityUpdates::Advisory.new(
      package:,
      version:,
      id:,
      title: "Bad thing",
      url: "https://example.test/#{id}",
      fixed_in:
    )
  end

  def pin_advisory(title:)
    SecurityUpdates::Advisory.new(
      package: "tom-select",
      version: "< 2.6.2",
      id: "high",
      title:,
      url: nil,
      fixed_in: ["latest"]
    )
  end

  def section(name)
    markdown[/^## #{name}\n(.*?)(?=^## |\z)/m, 1]
  end

  describe "#to_markdown" do
    context "when the advisory is gone after the update" do
      it "lists it as fixed with its reference and fix" do
        expect(section("Fixed")).to include("- `rack` 3.0.0: [CVE-1](https://example.test/CVE-1) Bad thing (fixed in ~> 3.1)")
      end

      it "omits the empty sections" do
        expect(markdown).not_to include("## Unresolved", "## Version changes")
      end
    end

    context "when the advisory remains with a different locked version" do
      let(:remaining) { [advisory(package: "rack", id: "CVE-1", version: "3.0.5")] }

      it "lists it only under Unresolved" do
        expect(section("Unresolved")).to include("`rack` 3.0.5")
        expect(markdown).not_to include("## Fixed")
      end
    end

    context "when there is no fixed version" do
      let(:found) { [advisory(package: "rack", id: "CVE-1", fixed_in: [])] }

      it "says so instead of rendering an empty version" do
        expect(markdown).to include("(no fixed version yet)")
        expect(markdown).not_to include("fixed in )")
      end
    end

    context "with an advisory that has no link or locked version" do
      let(:found) do
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
      end
      let(:remaining) { found }

      it "renders the bare id and omits the version" do
        expect(section("Unresolved")).to include("- `http://rubygems.org/`: insecure-source Gem source uses an insecure protocol (no fixed version yet)")
      end
    end

    context "with two pin advisories of the same severity, one still open" do
      let(:open_pin) { pin_advisory(title: "Prototype pollution") }
      let(:fixed_pin) { pin_advisory(title: "ReDoS in search") }
      let(:found) { [open_pin, fixed_pin] }
      let(:remaining) { [open_pin] }

      it "tells them apart by title" do
        expect(section("Fixed")).to include("ReDoS in search")
        expect(section("Fixed")).not_to include("Prototype pollution")
      end
    end

    context "with version changes" do
      let(:changes) { ["`rack` 3.0.0 → 3.1.0"] }

      it "lists them under Version changes" do
        expect(section("Version changes")).to eq("- `rack` 3.0.0 → 3.1.0\n")
      end
    end
  end

  describe "#unresolved?" do
    subject(:unresolved) { described_class.new(found:, remaining:, changes:).unresolved? }

    it { is_expected.to be false }

    context "when advisories remain" do
      let(:remaining) { found }

      it { is_expected.to be true }
    end
  end
end
