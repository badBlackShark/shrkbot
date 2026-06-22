require "rails_helper"

RSpec.describe Components::Icon do
  subject(:svg) { described_class.new(name, **options).call }

  let(:name) { "sun" }
  let(:options) { {} }

  it "renders the named heroicon inline" do
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
end
