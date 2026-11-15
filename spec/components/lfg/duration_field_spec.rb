# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Lfg::DurationField do
  subject(:html) do
    described_class.new(
      name: "lfg[cooldown_seconds]",
      value: 120,
      min: 0,
      max: 86_400,
      default: 300,
      base: :seconds,
      label: "Cooldown",
      help:
    ).render_in(view_context)
  end

  let(:view_context) { ApplicationController.new.view_context }
  let(:help) { "How long a member must wait between posts." }

  it "renders the label, help, and stepper with the given value" do
    expect(html).to include("Cooldown")
    expect(html).to include('name="lfg[cooldown_seconds]"')
    expect(html).to include('value="120"')
  end

  it "offers a reset to its default" do
    expect(html).to include("Reset to 5 minutes")
  end

  it "puts the help under the stepper" do
    expect(html.index("How long a member must wait")).to be > html.index('name="lfg[cooldown_seconds]"')
  end

  context "without help" do
    let(:help) { nil }

    it "renders no help line" do
      expect(Nokogiri::HTML5.fragment(html).css("p")).to be_empty
    end
  end
end
