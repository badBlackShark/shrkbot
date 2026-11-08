# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::Twitch::EndModeField do
  include_context "component view context"

  subject(:document) { Nokogiri::HTML.fragment(described_class.new(subscription:).render_in(view_context)) }

  let(:subscription) { build(:feed_subscription, :twitch) }
  let(:panels) { document.css("[data-option-panels-target=panel]").to_h { |panel| [panel["data-value"], panel] } }

  before { subscription.settings.live_end_mode = "keep" }

  it "offers the four modes in order" do
    expect(document.css("button[data-segmented-target=option]").map { |button| [button["data-value"], button.text] }).to eq(
      [["mark_ended_with_vod", "Ended, with VOD"], ["mark_ended", "Ended"], ["keep", "Keep live card"], ["delete", "Delete"]]
    )
  end

  it "stores the mode under the settings name and tells the panels when it changes" do
    input = document.at_css("input[name='subscription[live_end_mode]']")

    expect(input["value"]).to eq("keep")
    expect(input["data-action"]).to eq("input->option-panels#show")
  end

  it "shows only the selected mode's panel" do
    expect(panels.transform_values { |panel| panel.key?("hidden") }).to eq(
      "mark_ended_with_vod" => true, "mark_ended" => true, "keep" => false, "delete" => true
    )
  end

  it "previews the VOD link only for the VOD mode and nothing for delete" do
    expect(panels["mark_ended_with_vod"].text).to include("Watch the VOD")
    expect(panels["mark_ended"].text).not_to include("Watch the VOD")
    expect(panels["keep"].text).to include("Stream ended 5 minutes ago")
    expect(panels["delete"].text).to include("shrkbot deletes the post.")
    expect(panels["delete"].text).not_to include("Preview")
  end
end
