# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::VersionBadge do
  include_context "component view context"

  subject(:html) { described_class.new.render_in(view_context) }

  context "when a release is available" do
    before do
      allow(ReleaseInfo).to receive(:current).and_return(
        ReleaseInfo.new(number: "3.1.0", released_on: Date.new(2026, 7, 11))
      )
    end

    it "shows the version number" do
      expect(html).to include("v3.1.0")
    end

    it "links to the release notes" do
      expect(html).to include("href=\"https://github.com/badBlackShark/shrkbot/releases/tag/3.1.0\"")
    end

    it "labels the link for screen readers" do
      expect(html).to include("3.1.0 release notes")
    end

    it "shows the release date in a downward tooltip" do
      expect(html).to include("Released 11. Jul, 2026")
      expect(html).to include("top-full")
    end
  end

  context "when no release is available" do
    before { allow(ReleaseInfo).to receive(:current).and_return(nil) }

    it "renders nothing" do
      expect(html).to eq("")
    end
  end
end
