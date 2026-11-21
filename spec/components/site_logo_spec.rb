# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::SiteLogo do
  include_context "component view context"

  subject(:page) { Nokogiri::HTML.fragment(described_class.new(href: "/servers").render_in(view_context)) }

  it "links to the given path" do
    expect(page.at_css("a")["href"]).to eq("/servers")
  end

  it "renders the mascot as a chamfered tile with empty alt text, since the wordmark names the site" do
    image = page.at_css("img")

    expect(image["alt"]).to eq("")
    expect(image["class"]).to include("chamfer-tile-sm")
  end
end
