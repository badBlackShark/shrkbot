# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::RadioCardGroup do
  subject(:html) { described_class.new(**options).call }

  let(:options) do
    {
      name: "image_scanning[sensitivity]",
      value: "standard",
      options: [
        {value: "relaxed", title: "Relaxed", description: "Catches only the most obvious scams."},
        {value: "standard", title: "Standard", description: "Balanced detection for most servers."},
        {value: "strict", title: "Strict", description: "Maximises catch rate; more false positives."}
      ]
    }
  end

  it "renders all option titles and descriptions" do
    expect(html).to include("Relaxed").and include("Standard").and include("Strict")
    expect(html).to include("Catches only the most obvious scams.")
    expect(html).to include("Balanced detection for most servers.")
    expect(html).to include("Maximises catch rate; more false positives.")
  end

  it "marks the selected option checked" do
    expect(html).to include('value="standard"').and include("checked")
  end

  it "does not mark unselected options checked" do
    doc = Nokogiri::HTML5.fragment(html)
    checked_inputs = doc.css("input[type=radio][checked]")
    expect(checked_inputs.size).to eq(1)
    expect(checked_inputs.first["value"]).to eq("standard")
  end

  it "gives all inputs the same name" do
    doc = Nokogiri::HTML5.fragment(html)
    names = doc.css("input[type=radio]").map { |i| i["name"] }.uniq
    expect(names).to eq(["image_scanning[sensitivity]"])
  end

  it "renders a radiogroup wrapper" do
    expect(html).to include('role="radiogroup"')
  end

  context "with a label" do
    let(:options) do
      super().merge(label: "Detection sensitivity")
    end

    it "sets aria-label on the wrapper" do
      expect(html).to include("Detection sensitivity")
    end
  end

  context "with the first option selected" do
    let(:options) { super().merge(value: "relaxed") }

    it "checks the first option only" do
      doc = Nokogiri::HTML5.fragment(html)
      checked = doc.css("input[type=radio][checked]")
      expect(checked.size).to eq(1)
      expect(checked.first["value"]).to eq("relaxed")
    end
  end
end
