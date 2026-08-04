# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Welcomes::ConfigForm do
  subject(:html) do
    described_class.new(server_configuration: config).render_in(view_context)
  end

  let(:view_context) { ApplicationController.new.view_context }
  let(:config) { create(:server_configuration) }

  before do
    config.create_welcome_settings!
  end

  it "renders the channel card with the required marker" do
    expect(html).to include("This setting is required to enable the plugin")
  end

  it "shows the none-message when no channels have synced" do
    expect(html).to include("No channels have synced yet")
  end

  it "nests the ping-on-join toggle in the join message card" do
    expect(card_containing("welcomes[join_message]")).to include('name="welcomes[ping_on_join]"')
  end

  it "nests the suppress-removal-messages toggle in the leave message card" do
    expect(card_containing("welcomes[leave_message]")).to include('name="welcomes[suppress_removal_messages]"')
  end

  def card_containing(field)
    Nokogiri::HTML.fragment(html)
      .css("div.rounded-card")
      .find { |card| card.css("[name]").any? { |node| node["name"] == field } }
      .to_html
  end
end
