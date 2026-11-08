# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::RoleField do
  include_context "component view context"

  subject(:html) { described_class.new(subscription:, name: "subscription[live_role_id]", selected: nil).render_in(view_context) }

  let(:subscription) { build(:feed_subscription, :twitch) }

  it "renders a single-choice role select under the given name, with a no-ping placeholder" do
    expect(html).to include("Role to ping (optional)", 'name="subscription[live_role_id]"', "No ping")
    expect(html).not_to include("multiple")
  end

  it "feeds the live preview" do
    expect(html).to include('data-feed-preview-target="role"', 'data-action="change->feed-preview#render"')
  end
end
