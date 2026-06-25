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
end
