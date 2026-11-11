# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::WatchImage do
  subject(:html) { described_class.new(url:, plugin_key:, size:).call }

  let(:size) { :md }
  let(:plugin_key) { :steam }

  context "with an image url" do
    let(:url) { "https://shared.akamai.steamstatic.com/hades.jpg" }

    it "renders a lazy, alt-less image" do
      expect(html).to include(%(src="#{url}"), 'loading="lazy"', 'alt=""')
    end

    it "is a wide rectangle for Steam" do
      expect(html).to include("aspect-[460/215]", "w-46")
      expect(html).not_to include("rounded-full")
    end

    context "with Twitch" do
      let(:plugin_key) { :twitch }

      it "is a round avatar" do
        expect(html).to include("aspect-square", "rounded-full", "w-22")
        expect(html).not_to include("aspect-[460/215]")
      end
    end
  end

  context "without an image url" do
    let(:url) { nil }
    let(:size) { :list }

    it "renders a sunken placeholder of the same size instead" do
      expect(html).not_to include("<img")
      expect(html).to include("bg-surface-sunken", "w-30 sm:w-46")
    end
  end
end
