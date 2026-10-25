# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::VolumeLine do
  include_context "component view context"

  subject(:html) { described_class.new(volume:, plugin_key: :steam).render_in(view_context) }

  let(:patch_notes) { "Integrations::Steam::PatchNotesPublished" }
  let(:announcements) { "Integrations::Steam::AnnouncementPublished" }
  let(:articles) { "Integrations::Steam::ArticlePublished" }
  let(:counts) { {patch_notes => 3, announcements => 15, articles => 1} }
  let(:volume) { Integrations::Volume.new(counts:, sample_size: 20) }

  it "lists each type with a serial comma, in source order" do
    expect(html).to include("Last 20 posts: 3 patch notes, 15 announcements, and 1 article.")
  end

  context "when a type has no posts" do
    let(:counts) { {patch_notes => 3, announcements => 15} }

    it "leaves it out" do
      expect(html).to include("Last 20 posts: 3 patch notes and 15 announcements.")
      expect(html).not_to include("article")
    end
  end

  context "without a volume" do
    let(:volume) { nil }

    it "renders nothing" do
      expect(html).to eq("")
    end
  end

  context "with an empty sample" do
    let(:volume) { Integrations::Volume.new(counts: {}, sample_size: 0) }

    it "renders nothing" do
      expect(html).to eq("")
    end
  end
end
