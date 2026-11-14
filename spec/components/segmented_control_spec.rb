# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::SegmentedControl do
  subject(:html) do
    described_class.new(name: "mode", value: "a", label:, options: [{value: "a", label: "A"}, {value: "b", label: "B"}]).call
  end

  let(:label) { nil }

  it "stops the browser restoring the hidden value on a soft reload" do
    expect(html).to match(/<input type="hidden"[^>]*autocomplete="off"/)
  end

  context "with a label" do
    let(:label) { "Sensitivity" }

    it "names the group for screen readers" do
      expect(html).to include('role="group"')
      expect(html).to include('aria-label="Sensitivity"')
    end
  end
end
