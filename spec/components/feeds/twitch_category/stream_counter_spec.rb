# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::TwitchCategory::StreamCounter do
  include_context "component view context"

  subject(:counter) { Nokogiri::HTML.fragment(described_class.new(server_configuration:, category_id: "7").render_in(view_context)).at_css("p") }

  let(:server_configuration) { build(:server_configuration, discord_id: 42) }

  it "is a polite live region that starts on a placeholder" do
    expect(counter["aria-live"]).to eq("polite")
    expect(counter.text).to eq("Counting streams…")
  end

  it "points the controller at the category's stream endpoint" do
    expect(counter["data-controller"]).to eq("category-counter")
    expect(counter["data-category-counter-url-value"]).to eq("/servers/42/twitch/categories/7/streams")
  end

  it "hands the controller every sentence, with a slot for the number" do
    expect(counter["data-category-counter-many-value"]).to eq("With these settings, {number} streams would post right now.")
    expect(counter["data-category-counter-one-value"]).to eq("With these settings, 1 stream would post right now.")
    expect(counter["data-category-counter-none-value"]).to eq("No stream would post right now with these settings.")
    expect(counter["data-category-counter-failed-value"]).to eq("Couldn't reach Twitch to count streams.")
  end
end
