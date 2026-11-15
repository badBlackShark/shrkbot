# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::EventTypesCard do
  include_context "component view context"

  subject(:html) do
    described_class.new(subscription:, plugin_key: :steam, footer: Components::Feeds::Steam::UpdateTypesNote.new(subscription:)).render_in(view_context) { "volume" }
  end

  let(:subscription) { build(:steam_feed_subscription) }

  it "renders the block before the toggles and the footer after them" do
    toggles = html.rindex("checkbox")

    expect(html.index("volume")).to be < html.index("subscription[event_types]")
    expect(html.index("data-controller=\"live-warning\"")).to be > toggles
  end
end
