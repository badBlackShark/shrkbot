require "rails_helper"

RSpec.describe Components::Breadcrumb do
  subject(:html) { described_class.new(crumbs).call }

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
    expect(html).to include('class="font-medium text-text-secondary">Welcomes')
  end

  it "puts a separator between crumbs but not before the first" do
    expect(html.scan("<svg").size).to eq(crumbs.size - 1)
  end
end
