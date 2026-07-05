# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::UserAvatar do
  include_context "component view context"

  subject(:html) { described_class.new(user:, size:).render_in(view_context) }

  let(:user) { build(:user, avatar: "abc123", display_name: "Shark Bot") }
  let(:size) { :sm }

  it "renders the Discord avatar image" do
    expect(html).to include(user.avatar_url).and include("size-8")
  end

  context "without an avatar" do
    let(:user) { build(:user, avatar: nil, display_name: "Shark Bot") }

    it "falls back to initials" do
      expect(html).to include("SB").and include("bg-accent-soft")
    end
  end

  context "with the large size" do
    let(:size) { :lg }

    it "renders the larger frame" do
      expect(html).to include("size-16")
    end
  end
end
