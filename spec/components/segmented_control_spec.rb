# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::SegmentedControl do
  subject(:html) do
    described_class.new(name: "mode", value: "a", options: [{value: "a", label: "A"}, {value: "b", label: "B"}]).call
  end

  it "stops the browser restoring the hidden value on a soft reload" do
    expect(html).to match(/<input type="hidden"[^>]*autocomplete="off"/)
  end
end
