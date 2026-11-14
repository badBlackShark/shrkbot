# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::DurationStepper do
  include_context "component view context"

  subject(:html) { described_class.new(**options).render_in(view_context) }

  let(:options) { {name: "lfg[cooldown_seconds]", value: 300, base: :seconds, min: 0, max: 86_400, default: 300} }
  let(:fragment) { Nokogiri::HTML5.fragment(html) }
  let(:input) { fragment.at_css("input[type=number]") }
  let(:field) { fragment.at_css("input[type=hidden]") }
  let(:selected) { fragment.at_css("option[selected]") }
  let(:wrapper) { fragment.at_css("[data-controller=number-stepper]") }

  it "shows the value in the largest unit that divides it" do
    expect(input["value"]).to eq("5")
    expect(selected.text).to eq("minutes")
    expect(input.key?("name")).to be(false)
  end

  it "picks the unit with the shared fixed picker" do
    select = fragment.at_css("select")
    expect(select.key?("data-tom-select-fixed-value")).to be(true)
    expect(select["data-number-stepper-target"]).to eq("unit")
    expect(select["data-action"]).to eq("change->number-stepper#changeUnit")
  end

  it "names the unit picker for screen readers" do
    expect(fragment.at_css("select")["aria-label"]).to eq("Unit")
  end

  it "submits the stored value under the field's name" do
    expect(field["name"]).to eq("lfg[cooldown_seconds]")
    expect(field["value"]).to eq("300")
    expect(field["data-number-stepper-target"]).to eq("field")
  end

  it "hides the reset while the value is the default" do
    expect(fragment.at_css("[data-number-stepper-target=reset]").key?("hidden")).to be(true)
  end

  context "when the value only divides into seconds" do
    let(:options) { super().merge(value: 90) }

    it "falls back to the unit that divides it" do
      expect(input["value"]).to eq("90")
      expect(selected.text).to eq("seconds")
    end

    it "names the default's unit in the reset" do
      reset = fragment.at_css("[data-number-stepper-target=reset]")
      expect(reset.key?("hidden")).to be(false)
      expect(reset.at_css("button")["aria-label"]).to eq("Reset to 5 minutes")
      expect(wrapper["data-number-stepper-default-value"]).to eq("300")
      expect(wrapper["data-number-stepper-default-unit-value"]).to eq("60")
    end
  end

  context "when the value is zero" do
    let(:options) { super().merge(value: 0) }

    it "shows zero in the base unit" do
      expect(selected.text).to eq("seconds")
    end
  end

  context "when the field stores minutes" do
    let(:options) { {name: "lfg[post_lifetime_minutes]", value: 360, base: :minutes, min: 5, max: 10_080, default: 360} }

    it "offers only units the field can store" do
      expect(fragment.css("option").map(&:text)).to eq(%w[minutes hours])
      expect(fragment.css("option").map { |option| option["value"] }).to eq(%w[1 60])
    end

    it "scales the bounds to the shown unit" do
      expect(input["min"]).to eq("1")
      expect(input["max"]).to eq("168")
    end
  end

  context "when the value is inherited" do
    let(:options) { {name: "destination[post_delay_minutes]", value: nil, base: :minutes, min: 0, max: 10_080, placeholder: 30} }

    it "leaves the field empty and shows the placeholder in the shown unit" do
      expect(input.key?("value")).to be(false)
      expect(input["placeholder"]).to eq("30")
      expect(field.key?("value")).to be(false)
      expect(fragment.at_css("[data-number-stepper-target=reset]")).to be_nil
      expect(input["data-action"]).to eq("input->number-stepper#sync")
      expect(wrapper["data-number-stepper-placeholder-value"]).to eq("30")
    end
  end

  context "when the placeholder does not fit the shown unit" do
    let(:options) { {name: "destination[post_delay_minutes]", value: 120, base: :minutes, min: 0, max: 10_080, placeholder: 15} }

    it "rounds it to two decimals" do
      expect(input["placeholder"]).to eq("0.25")
    end
  end
end
