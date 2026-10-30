# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::SubscriptionRow do
  include_context "component view context"

  subject(:html) do
    described_class.new(subscription:, plugin_key: :steam, channel_label: "#news", roles:).render_in(view_context)
  end

  let(:subscription) { create(:feed_subscription) }

  context "without roles" do
    let(:roles) { [] }

    it "says no ping" do
      expect(html).to include("no ping")
    end
  end

  context "with distinct roles" do
    let(:roles) { %w[Gamers Patchers] }

    it "lists them" do
      expect(html).to include("pings @Gamers and @Patchers")
    end
  end

  context "with a role that no longer exists" do
    let(:roles) { ["Gamers", nil] }

    it "says the role was deleted" do
      expect(html).to include("pings a role that was deleted")
    end
  end
end
