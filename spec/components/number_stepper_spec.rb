# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::NumberStepper do
  include_context "component view context"

  subject(:html) { described_class.new(**options).render_in(view_context) }

  let(:options) { {name: "spam_protection[channel_threshold]", value: 4, min: 2, default: 4, unit: "channels"} }

  it "renders a number input with the correct name and value" do
    expect(html).to include('name="spam_protection[channel_threshold]"')
    expect(html).to include('value="4"')
    expect(html).to include('type="number"')
  end

  it "sets the min attribute on the input" do
    expect(html).to include('min="2"')
  end

  it "renders minus and plus buttons wired to the controller" do
    expect(html).to include("click->number-stepper#decrement")
    expect(html).to include("click->number-stepper#increment")
  end

  it "marks the input as the controller target" do
    expect(html).to include('data-number-stepper-target="input"')
  end

  it "shows the recommended default subscript" do
    expect(html).to include("Recommended default: 4")
  end

  it "renders the unit label when provided" do
    expect(html).to include("channels")
  end

  context "when max is provided" do
    let(:options) { {name: "image_scanning[custom_keyword_min_hits]", value: 1, min: 1, default: 2, max: 5} }

    it "sets the max attribute and data value on the controller wrapper" do
      expect(html).to include('max="5"')
      expect(html).to include("data-number-stepper-max-value")
    end
  end

  context "when max is omitted" do
    it "omits the max attribute and max data value" do
      expect(html).not_to include("max=")
      expect(html).not_to include("data-number-stepper-max-value")
    end
  end
end
