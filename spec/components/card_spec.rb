require "rails_helper"

RSpec.describe Components::Card do
  subject(:html) { described_class.new(**options).call { "body" } }

  let(:options) { {} }

  it "renders a bordered warm surface as a div" do
    expect(html).to include("<div").and include("rounded-card").and include("bg-surface-card")
    expect(html).to include("border-border-default").and include("body")
  end

  it "uses medium padding by default" do
    expect(html).to include("p-5")
  end

  context "when enabled" do
    let(:options) { {enabled: true} }

    it "swaps to the faint teal border" do
      expect(html).to include("border-accent-soft-bd")
      expect(html).not_to include("border-border-default")
    end
  end

  context "with an href" do
    let(:options) { {href: "/servers/1"} }

    it "renders a link" do
      expect(html).to include("<a").and include('href="/servers/1"')
    end
  end

  context "when lifted" do
    let(:options) { {lift: true} }

    it "adds the hover-raise" do
      expect(html).to include("card-lift")
    end
  end

  context "with no padding" do
    let(:options) { {padding: :none} }

    it "omits the padding utility" do
      expect(html).not_to include("p-5")
    end
  end
end
