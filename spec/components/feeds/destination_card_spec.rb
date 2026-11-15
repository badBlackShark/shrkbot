# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::DestinationCard do
  include_context "component view context"

  subject(:document) { Nokogiri::HTML.fragment(described_class.new(subscription:).render_in(view_context)) }

  let(:subscription) { build(:feed_subscription, :twitch) }

  it "has no heading" do
    expect(document.to_html).not_to include("Where to post")
    expect(document.at_css("h2")).to be_nil
  end

  it "requires the channel" do
    expect(document.at_css("select[name='subscription[channel_id]']")["aria-required"]).to eq("true")
  end

  it "offers the role to ping" do
    expect(document.at_css("select[name='subscription[role_id]']")).to be_present
    expect(document.text).to include("Role to ping")
    expect(document.to_html).to include("No ping")
  end

  context "with a role on the follow" do
    before do
      create(:server_role, server_configuration: subscription.server_configuration, discord_id: 321)
      subscription.settings.role_id = 321
    end

    it "preselects it" do
      expect(document.at_css("select[name='subscription[role_id]'] option[selected]")["value"]).to eq("321")
    end
  end
end
