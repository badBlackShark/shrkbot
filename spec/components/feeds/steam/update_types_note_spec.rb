# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::Steam::UpdateTypesNote do
  include_context "component view context"

  subject(:note) { Nokogiri::HTML5.fragment(described_class.new(subscription:).render_in(view_context)).at_css("[data-controller=live-warning]") }

  let(:subscription) { build(:steam_feed_subscription) }
  let(:followed) { ["Integrations::Steam::PatchNotesPublished"] }

  before { followed.each { |type| subscription.subscribed_events.build(event_type: type) } }

  it "watches both update-type toggles for exactly one being on" do
    expect(JSON.parse(note["data-live-warning-fields-value"])).to eq(
      [
        "subscription[event_types][Integrations::Steam::PatchNotesPublished]",
        "subscription[event_types][Integrations::Steam::AnnouncementPublished]"
      ]
    )
    expect(note["data-live-warning-rule-value"]).to eq("exactly-one")
  end

  it "shows when only patch notes are followed" do
    expect(note.key?("hidden")).to be(false)
  end

  context "when patch notes and announcements are followed" do
    let(:followed) { %w[Integrations::Steam::PatchNotesPublished Integrations::Steam::AnnouncementPublished] }

    it "is hidden" do
      expect(note.key?("hidden")).to be(true)
    end
  end

  context "when only articles are followed" do
    let(:followed) { ["Integrations::Steam::ArticlePublished"] }

    it "is hidden" do
      expect(note.key?("hidden")).to be(true)
    end
  end

  context "when announcements are marked for removal" do
    let(:followed) { %w[Integrations::Steam::PatchNotesPublished Integrations::Steam::AnnouncementPublished] }

    before { subscription.subscribed_events.find { |event| event.event_type.end_with?("AnnouncementPublished") }.mark_for_destruction }

    it "shows" do
      expect(note.key?("hidden")).to be(false)
    end
  end
end
