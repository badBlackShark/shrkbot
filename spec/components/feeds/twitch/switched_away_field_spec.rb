# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::Twitch::SwitchedAwayField do
  include_context "component view context"

  subject(:document) { Nokogiri::HTML.fragment(described_class.new(subscription:).render_in(view_context)) }

  let(:subscription) { build(:feed_subscription, :twitch) }
  let(:panels) { document.css("[data-option-panels-target=panel]").to_h { |panel| [panel["data-value"], panel] } }

  before { subscription.settings.switched_away = "delete" }

  it "offers both modes in order" do
    expect(document.css("button[data-segmented-target=option]").map { |button| [button["data-value"], button.text] }).to eq(
      [["summary", "Show it switched"], ["delete", "Delete it"]]
    )
  end

  it "stores the mode under the settings name and tells the panels when it changes" do
    input = document.at_css("input[name='subscription[switched_away]']")

    expect(input["value"]).to eq("delete")
    expect(input["data-action"]).to eq("input->option-panels#show")
  end

  it "shows only the selected mode's panel" do
    expect(panels.transform_values { |panel| panel.key?("hidden") }).to eq("summary" => true, "delete" => false)
  end

  it "previews the switched card for the summary only" do
    expect(panels["summary"].text).to include("Preview", "Switched to Just Chatting")
    expect(panels["delete"].text).to include("posts it again, without a ping")
    expect(panels["delete"].text).not_to include("Preview")
  end
end
