# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Admin::OwnerDmCard do
  include_context "component view context"

  subject(:html) { described_class.new.render_in(view_context) }

  context "when owner_error_dms is enabled" do
    before { BotSetting.owner_error_dms = true }

    it "renders the card with a checked toggle" do
      expect(html).to include("owner-dm-card")
      expect(html).to include("checked")
    end
  end

  context "when owner_error_dms is disabled" do
    before { BotSetting.owner_error_dms = false }

    it "renders the card with an unchecked toggle" do
      expect(html).to include("owner-dm-card")
      expect(html).not_to include('checked="checked"')
    end
  end
end
