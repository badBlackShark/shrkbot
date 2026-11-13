# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Logging::ConfigForm do
  subject(:html) do
    described_class.new(server_configuration: config).render_in(view_context)
  end

  let(:view_context) { ApplicationController.new.view_context }
  let(:config) { create(:server_configuration) }

  before do
    create(:logging_settings, server_configuration: config)
  end

  it "renders the channel card with the required marker" do
    expect(html).to include("This setting is required to enable the plugin")
  end

  it "shows the none-message when no channels have synced" do
    expect(html).to include("No channels have synced yet")
  end

  it "counts each event group as N of M on" do
    counts = Nokogiri::HTML.fragment(html).css("[data-event-group-target=count]").map { |count| count.parent.text.squish }

    expect(counts).to all(match(/\A\d+ of \d+ on\z/))
  end

  it "wires the channel-warning Stimulus controller on the card" do
    expect(html).to include('data-controller="channel-warning"')
  end
end
