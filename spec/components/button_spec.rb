require "rails_helper"

RSpec.describe Components::Button do
  subject(:html) { described_class.new(**options).call { "Save" } }

  let(:options) { {} }

  it "renders a button by default" do
    expect(html).to include("<button").and include("Save")
    expect(html).not_to include("<a")
  end

  it "defaults to a non-submitting button" do
    expect(html).to include('type="button"')
  end

  context "as a submit button" do
    let(:options) { {type: "submit"} }

    it "submits" do
      expect(html).to include('type="submit"')
    end
  end

  context "with an href" do
    let(:options) { {href: "/servers"} }

    it "renders a link, not a button" do
      expect(html).to include("<a").and include('href="/servers"')
      expect(html).not_to include("<button")
    end
  end

  context "primary variant" do
    let(:options) { {variant: :primary} }

    it "carries the chamfered CTA edge and the fill colour" do
      expect(html).to include("chamfer-cta").and include("bg-accent-fill")
    end
  end

  context "ghost variant" do
    let(:options) { {variant: :ghost} }

    it "is rounded, not chamfered" do
      expect(html).to include("rounded-control")
      expect(html).not_to include("chamfer-cta")
    end
  end

  context "when disabled" do
    let(:options) { {disabled: true} }

    it "sets the attribute and dims" do
      expect(html).to include("disabled").and include("opacity-50")
    end
  end

  context "when full-width" do
    let(:options) { {full: true} }

    it "spans the row" do
      expect(html).to include("w-full")
    end
  end

  context "with leading and trailing icons" do
    subject(:html) { described_class.new(icon: "plus", trailing_icon: "arrow-right").call { "Add" } }

    it "renders both glyphs around the label" do
      expect(html.scan("<svg").size).to eq(2)
    end
  end

  describe ".css" do
    it "exposes the class string for form helpers to borrow" do
      expect(described_class.css(variant: :primary, full: true))
        .to include("bg-accent-fill").and include("w-full")
    end
  end
end
