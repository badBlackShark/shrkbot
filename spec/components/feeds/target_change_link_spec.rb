# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::TargetChangeLink do
  include_context "component view context"

  subject(:link) { Nokogiri::HTML.fragment(described_class.new(href: "/servers/1/steam/subscriptions/new").render_in(view_context)).at_css("a") }

  it "links back to the lookup with its label" do
    expect(link["href"]).to eq("/servers/1/steam/subscriptions/new")
    expect(link.text).to eq("Not this one?")
  end
end
