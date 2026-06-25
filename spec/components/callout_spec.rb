# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Callout do
  subject(:html) { described_class.new(**options).call { "Heads up." } }

  let(:options) { {variant: :warning} }

  it "renders a tinted bordered box with the body and default icon" do
    expect(html).to include("Heads up.").and include("bg-warning-soft").and include("border-warning/30")
    expect(html).to include(PhosphorIcons::Icon.new("warning", style: :regular, class: "mt-0.5 size-[18px] flex-none text-warning").to_svg)
  end

  context "info variant" do
    let(:options) { {variant: :info} }

    it "uses the teal tint and the info glyph" do
      expect(html).to include("bg-accent-soft").and include("border-accent-soft-bd")
      expect(html).to include(PhosphorIcons::Icon.new("info", style: :regular, class: "mt-0.5 size-[18px] flex-none text-accent").to_svg)
    end
  end

  context "with an icon override" do
    let(:options) { {variant: :success, icon: "lock"} }

    it "renders the chosen glyph instead of the default" do
      expect(html).to include(PhosphorIcons::Icon.new("lock", style: :regular, class: "mt-0.5 size-[18px] flex-none text-success").to_svg)
    end
  end
end
