# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Lfg::MinDaysField do
  subject(:html) do
    described_class.new(
      name: "lfg[default_min_membership_days]",
      value: 7,
      label: "Minimum membership",
      placeholder: "5",
      unit: "days"
    ).render_in(view_context)
  end

  let(:view_context) { ApplicationController.new.view_context }

  it "renders the label, unit, and the given value" do
    expect(html).to include("Minimum membership")
    expect(html).to include("days")
    expect(html).to include('name="lfg[default_min_membership_days]"')
    expect(html).to include('value="7"')
  end

  it "steps through the custom buttons rather than the browser's spinners" do
    expect(html).to include("click->number-stepper#decrement")
    expect(html).to include("click->number-stepper#increment")
    expect(html).to include("[&::-webkit-inner-spin-button]:appearance-none")
  end

  it "bounds the input to the range the model allows" do
    expect(html).to include('min="0"')
    expect(html).to include('max="3650"')
  end

  it "shows the given placeholder" do
    expect(html).to include('placeholder="5"')
  end

  it "omits the recommended-default subscript, since blank is the default" do
    expect(html).not_to include("Recommended default")
  end
end
