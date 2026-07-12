# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Tooltip do
  subject(:html) { described_class.new(text: "Latest release", placement:).call { "trigger" } }

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
end
