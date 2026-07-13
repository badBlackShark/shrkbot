# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::PublicShell do
  include_context "component view context"

  subject(:html) { described_class.new(user:).render_in(view_context) { "" } }

  context "when logged out" do
    let(:user) { nil }

    it "links the logo to the landing page" do
      expect(html).to include('<a href="/" class="flex items-center gap-2">')
    end
  end

  context "when logged in" do
    let(:user) { create(:user) }

    it "links the logo to the servers dashboard" do
      expect(html).to include('<a href="/servers" class="flex items-center gap-2">')
    end
  end
end
