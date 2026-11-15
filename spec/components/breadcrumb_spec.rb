require "rails_helper"

RSpec.describe Components::Breadcrumb do
  include_context "component view context"

  subject(:html) { described_class.new(crumbs).render_in(view_context) }

  let(:crumbs) do
    [
      {label: "Servers", href: "/servers"},
      {label: "Dev Refuge", href: "/servers/1"},
      {label: "Welcomes"}
    ]
  end

  it "links every crumb that carries an href" do
    expect(html).to include('href="/servers"').and include("Servers")
    expect(html).to include('href="/servers/1"').and include("Dev Refuge")
  end

  it "renders the hrefless final crumb as plain current text, not a link" do
    expect(Nokogiri::HTML.fragment(html).at_css("span.font-medium").text).to eq("Welcomes")
  end

  it "labels the nav as a breadcrumb" do
    expect(Nokogiri::HTML.fragment(html).at_css("nav")["aria-label"]).to eq("Breadcrumb")
  end

  it "marks only the last crumb as the current page" do
    current = Nokogiri::HTML.fragment(html).css("[aria-current]")
    expect(current.map(&:text)).to eq(["Welcomes"])
    expect(current.first["aria-current"]).to eq("page")
  end

  it "puts a separator between crumbs but not before the first" do
    expect(html.scan("<svg").size).to eq(crumbs.size - 1)
  end
end
