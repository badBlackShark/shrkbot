# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::WatchImage do
  subject(:html) { described_class.new(url:, size:).call }

  let(:size) { :md }

  context "with an image url" do
    let(:url) { "https://shared.akamai.steamstatic.com/hades.jpg" }

    it "renders a lazy, alt-less image" do
      expect(html).to include(%(src="#{url}"), 'loading="lazy"', 'alt=""')
    end
  end

  context "without an image url" do
    let(:url) { nil }
    let(:size) { :sm }

    it "renders a sunken placeholder of the same size instead" do
      expect(html).not_to include("<img")
      expect(html).to include("bg-surface-sunken", "w-30")
    end
  end
end
