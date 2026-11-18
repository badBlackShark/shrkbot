# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::SegmentedControl do
  subject(:html) do
    described_class.new(name: "mode", value: "a", label:, options: [{value: "a", label: "A"}, {value: "b", label: "B"}]).call
  end

  let(:label) { "Sensitivity" }

  it "stops the browser restoring the hidden value on a soft reload" do
    expect(html).to match(/<input type="hidden"[^>]*autocomplete="off"/)
  end

  it "names the group for screen readers" do
    expect(html).to include('role="radiogroup"')
    expect(html).to include('aria-label="Sensitivity"')
  end

  it "makes each button a radio, checked only for the current value" do
    buttons = Nokogiri::HTML5.fragment(html).css("button")

    expect(buttons.map { |b| [b["role"], b["aria-checked"], b["tabindex"]] }).to eq(
      [["radio", "true", "0"], ["radio", "false", "-1"]]
    )
    expect(html).not_to include("aria-pressed")
  end
end
