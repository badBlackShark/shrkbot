# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Badge do
  subject(:html) { described_class.new(**options).call { "Enabled" } }

  let(:options) { {variant: :success} }

  it "renders the label in the variant's tone" do
    expect(html).to include("Enabled").and include("bg-success-soft").and include("text-success")
  end

  it "is a pill by default with no dot" do
    expect(html).to include("rounded-full")
    expect(html).not_to include("size-1.5")
  end

  context "with a dot" do
    let(:options) { {variant: :success, dot: true} }

    it "renders a leading status dot" do
      expect(html).to include("size-1.5").and include("bg-success")
    end
  end

  context "as a chip" do
    let(:options) { {variant: :brand, shape: :chip} }

    it "uses the sharper chip radius and brand tone" do
      expect(html).to include("rounded-chip").and include("bg-accent-soft")
      expect(html).not_to include("rounded-full")
    end
  end

  context "copper variant" do
    let(:options) { {variant: :copper} }

    it "uses the copper wayfinding tone" do
      expect(html).to include("bg-accent-2-soft").and include("text-accent-2-text")
    end
  end

  it "outlines every variant so the faint fills keep their edge on cream surfaces" do
    outlines = described_class::VARIANTS.each_key.map { |variant| described_class.new(variant:).call { "Enabled" } }

    expect(outlines).to all(match(/class="[^"]*\bborder\b[^"]*\sborder-[a-z0-9-]+/))
  end
end
