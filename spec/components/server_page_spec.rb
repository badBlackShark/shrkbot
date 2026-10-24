# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::ServerPage do
  include_context "component view context"

  subject(:html) do
    described_class.new(
      server_configuration: config,
      crumbs: [{label: "Steam News", href: "/steam"}, {label: "Add a game"}]
    ).render_in(view_context) { "page body" }
  end

  let(:config) { create(:server_configuration, discord_id: 900_000_001, name:) }
  let(:name) { "Dev Refuge" }

  it "renders Servers, the server name and the given crumbs in order, then the block" do
    expect(html).to match(/Servers.*Dev Refuge.*Steam News.*Add a game.*page body/m)
  end

  context "when the server configuration has no name" do
    let(:name) { nil }

    it "falls back to the generic dashboard label" do
      expect(html).to match(/Servers.*Dashboard.*Steam News/m)
    end
  end
end
