# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::EventTypesCard do
  include_context "component view context"

  subject(:document) { Nokogiri::HTML.fragment(html) }

  let(:html) do
    described_class.new(subscription:, plugin_key: :steam, footer: Components::Feeds::Steam::UpdateTypesNote.new(subscription:)).render_in(view_context) { "volume" }
  end
  let(:subscription) { build(:steam_feed_subscription) }
  let(:first_toggle) { document.at_css("input[type=checkbox]") }
  let(:footer) { document.at_css("[data-controller=live-warning]") }

  it "renders the block before the toggles and the footer after them" do
    expect(first_toggle.xpath("preceding::text()").map(&:text)).to include("volume")
    expect(footer.xpath("preceding::input[@type='checkbox']")).not_to be_empty
  end
end
