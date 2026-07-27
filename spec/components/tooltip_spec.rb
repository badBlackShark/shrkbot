# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Tooltip do
  subject(:html) { described_class.new(text: "Latest release", placement:, align:, width:).call { "trigger" } }

  let(:placement) { :up }
  let(:align) { :right }
  let(:width) { "max-w-64" }

  context "with the default upward placement" do
    let(:placement) { :up }

    it "anchors the bubble above the trigger" do
      expect(html).to include("bottom-full")
    end
  end

  context "with downward placement" do
    let(:placement) { :down }

    it "anchors the bubble below the trigger" do
      expect(html).to include("top-full")
    end
  end

  context "with default alignment and width" do
    it "anchors the bubble to the right and caps it at the default width" do
      expect(html).to include("right-0")
      expect(html).to include("max-w-64")
    end
  end

  context "with left alignment" do
    let(:align) { :left }

    it "anchors the bubble to the left" do
      expect(html).to include("left-0")
    end
  end

  context "with a custom width" do
    let(:width) { "max-w-[11rem]" }

    it "replaces the default width" do
      expect(html).to include("max-w-[11rem]")
      expect(html).not_to include("max-w-64")
    end
  end

  context "with an unknown alignment" do
    let(:align) { :center }

    it "raises" do
      expect { html }.to raise_error(KeyError)
    end
  end
end
