# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Icon do
  subject(:svg) { described_class.new(name, **options).call }

  let(:name) { "sun" }
  let(:options) { {} }

  it "renders the named Phosphor icon inline" do
    expect(svg).to include("<svg").and include('fill="currentColor"')
  end

  it "applies a default size class" do
    expect(svg).to include("size-5")
  end

  it "defaults to the regular weight" do
    expect(described_class.new("users-three").call)
      .to eq(PhosphorIcons::Icon.new("users-three", style: :regular, class: "size-5").to_svg)
  end

  context "with a provided class" do
    let(:options) { {class: "size-6 text-ink-500"} }

    it "uses it instead of the default" do
      expect(svg).to include("size-6").and include("text-ink-500")
      expect(svg).not_to include("size-5")
    end
  end

  context "with a weight" do
    subject(:svg) { described_class.new("users-three", weight: :fill).call }

    it "renders that Phosphor style" do
      expect(svg).to eq(PhosphorIcons::Icon.new("users-three", style: :fill, class: "size-5").to_svg)
    end
  end

  context "with an unknown name" do
    let(:name) { "definitely-not-an-icon" }

    it "raises rather than rendering a blank, so typos surface loudly" do
      expect { svg }.to raise_error(PhosphorIcons::IconNotFoundError)
    end
  end

  context "with a custom glyph name" do
    let(:name) { "megaphone-slash" }

    it "renders an svg without raising IconNotFoundError" do
      expect { svg }.not_to raise_error
      expect(svg).to include("<svg").and include("viewBox=\"0 0 256 256\"")
    end

    it "applies the default size class" do
      expect(svg).to include("size-5")
    end

    context "with a provided class" do
      let(:options) { {class: "size-8 text-danger"} }

      it "spreads options onto the svg tag" do
        expect(svg).to include("size-8").and include("text-danger")
      end
    end

    it "delegates real Phosphor names normally" do
      real_svg = described_class.new("sun").call
      expect(real_svg).to eq(PhosphorIcons::Icon.new("sun", style: :regular, class: "size-5").to_svg)
    end

    context "with an injection attempt in an option value" do
      let(:options) { {data_probe: %("><script>alert(1)</script>)} }

      it "escapes the value so it can't break out of the attribute" do
        expect(svg).not_to include("<script>")
        expect(svg).to include("&quot;").and include("&lt;script&gt;")
      end
    end
  end
end
