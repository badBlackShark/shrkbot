require "rails_helper"

RSpec.describe Components::Icon do
  subject(:svg) { described_class.new(name, **options).call }

  let(:name) { "sun" }
  let(:options) { {} }

  it "renders an inline svg" do
    expect(svg).to include("<svg")
  end

  it "applies a default size class" do
    expect(svg).to include('class="size-5"')
  end

  context "with a provided class" do
    let(:options) { {class: "size-6 text-ink-500"} }

    it "uses it instead of the default" do
      expect(svg).to include("size-6").and include("text-ink-500")
      expect(svg).not_to include("size-5")
    end
  end

  context "with a kit (Lucide) name" do
    let(:name) { "users-round" }

    it "maps it to the matching heroicon" do
      expect(svg).to eq(described_class.new("users").call)
    end
  end

  context "with an unmapped name" do
    let(:name) { "chevron-down" }

    it "passes it straight through to heroicons" do
      expect(svg).to include("<svg")
    end
  end
end
