# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::RoleField do
  include_context "component view context"

  subject(:html) { described_class.new(subscription:, name: "subscription[live_role_id]", selected: nil, label: "Role to ping", placeholder: "No ping").render_in(view_context) }

  let(:subscription) { build(:feed_subscription, :twitch) }

  it "renders a single-choice role select under the given name, with a no-ping placeholder" do
    expect(html).to include("Role to ping", 'name="subscription[live_role_id]"', "No ping")
    expect(html).not_to include("multiple")
  end

  it "offers no no-ping option by default" do
    expect(Nokogiri::HTML.fragment(html).at_css("option[value='0']")).to be_nil
  end

  context "with a no-ping label" do
    subject(:html) { described_class.new(subscription:, name: "subscription[live_role_id]", selected: nil, label: "Role override", placeholder: "Same as above", no_ping_label: "No ping").render_in(view_context) }

    it "offers it first among the roles, with the value 0" do
      option = Nokogiri::HTML.fragment(html).at_css("select option[value='0']")

      expect([option.text, option.previous_element&.[]("value")]).to eq(["No ping", ""])
    end
  end

  it "feeds the live preview" do
    expect(html).to include('data-feed-preview-target="role"', 'data-action="change->feed-preview#render"')
  end
end
