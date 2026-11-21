# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::SegmentedControl do
  subject(:html) do
    described_class.new(name: "mode", value:, label:, options: [{value: "a", label: "A"}, {value: "b", label: "B"}]).call
  end

  let(:label) { "Sensitivity" }
  let(:value) { "a" }

  it "stops the browser restoring the hidden value on a soft reload" do
    expect(html).to match(/<input type="hidden"[^>]*autocomplete="off"/)
  end

  let(:fragment) { Nokogiri::HTML5.fragment(html) }
  let(:buttons) { fragment.css("button") }
  let(:group) { fragment.at_css("[role=radiogroup]") }

  it "names the group for screen readers" do
    expect(group["aria-label"]).to eq("Sensitivity")
  end

  it "wires keyboard navigation on the group and selection on each button" do
    expect(group["data-action"]).to eq("keydown->segmented#keydown")
    expect(buttons.map { |b| b["data-action"] }).to all(eq("segmented#select"))
  end

  it "makes each button a radio, checked only for the current value" do
    expect(buttons.map { |b| [b["role"], b["aria-checked"], b["tabindex"]] }).to eq(
      [["radio", "true", "0"], ["radio", "false", "-1"]]
    )
    expect(html).not_to include("aria-pressed")
  end

  context "when no option matches the value" do
    let(:value) { "missing" }

    it "keeps the first option tabbable so the group stays reachable" do
      expect(buttons.map { |b| [b["aria-checked"], b["tabindex"]] }).to eq([["false", "0"], ["false", "-1"]])
    end
  end
end
