# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::PluginTile do
  subject(:html) { described_class.new(**options).call }

  let(:options) { {icon: "users-three"} }

  it "is always chamfered and renders the glyph" do
    expect(html).to include("chamfer-tile").and include("<svg")
  end

  context "when enabled" do
    let(:options) { {icon: "users-three", enabled: true} }

    it "fills with teal and uses the fill-weight glyph" do
      expect(html).to include("bg-accent-fill").and include("text-white")
      expect(html).to eq(described_class.new(icon: "users-three", enabled: true).call)
      expect(html).to include(PhosphorIcons::Icon.new("users-three", style: :fill, class: "size-5").to_svg)
    end
  end

  context "when disabled" do
    let(:options) { {icon: "scroll", enabled: false} }

    it "is muted sand with a regular-weight glyph" do
      expect(html).to include("bg-surface-sunken").and include("text-text-muted")
      expect(html).to include(PhosphorIcons::Icon.new("scroll", style: :regular, class: "size-5").to_svg)
    end
  end

  context "at a larger size" do
    let(:options) { {icon: "users-three", size: :lg} }

    it "scales the box and glyph" do
      expect(html).to include("size-12").and include("size-6")
    end
  end
end
