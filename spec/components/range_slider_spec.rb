# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::RangeSlider do
  subject(:html) { described_class.new(**options).call }

  let(:base_options) do
    {
      name: "spam_protection[similarity]",
      label: "Match strictness",
      min_caption: "loosely similar",
      max_caption: "identical"
    }
  end
  let(:options) { base_options.merge(value: 0.85) }

  it "renders a hidden input with the stored float value and correct name" do
    expect(html).to include('type="hidden"')
    expect(html).to include('name="spam_protection[similarity]"')
    expect(html).to include('value="0.85"')
  end

  it "marks the hidden input as a controller target" do
    expect(html).to include('data-range-slider-target="hidden"')
  end

  it "renders a range input without a name (display only)" do
    expect(html).to include('type="range"')
    range_input = html[/<input[^>]*type="range"[^>]*>/, 0]
    expect(range_input).not_to include("name=")
  end

  it "converts the stored float to a percent value on the range input" do
    expect(html).to include('value="85"')
  end

  it "marks the range input as a controller target and wires the update action" do
    expect(html).to include('data-range-slider-target="range"')
    expect(html).to include("input->range-slider#update")
  end

  it "renders the readout target showing the initial percent" do
    expect(html).to include('data-range-slider-target="readout"')
    expect(html).to include("85%")
  end

  it "renders the endpoint captions and aria label it was given" do
    expect(html).to include("loosely similar")
    expect(html).to include("identical")
    expect(html).to include('aria-label="Match strictness"')
  end

  context "with value 0.75 (minimum)" do
    let(:options) { base_options.merge(value: 0.75) }

    it "shows 75 on the range and 0.75 on the hidden field" do
      expect(html).to include('value="75"')
      expect(html).to include('value="0.75"')
    end
  end

  context "with value 1.0 (maximum)" do
    let(:options) { base_options.merge(value: 1.0) }

    it "shows 100 on the range and 1.0 on the hidden field" do
      expect(html).to include('value="100"')
      expect(html).to include('value="1.0"')
    end
  end
end
