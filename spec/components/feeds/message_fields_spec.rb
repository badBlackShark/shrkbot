# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::MessageFields do
  include_context "component view context"

  subject(:html) { described_class.new(subscription:, plugin_key:, event_type:, event: nil).render_in(view_context) }

  let(:plugin_key) { :steam }
  let(:event_type) { "Integrations::Steam::PatchNotesPublished" }
  let(:subscription) { build(:feed_subscription, watch: build(:integration_watch, name: "Hades II")) }
  let(:chips) { html.scan(/data-clipboard-text-param="\{(\w+)\}"/).flatten }

  it "lists the placeholders once, before the message and the push text" do
    expect(chips).to eq(%w[game feed title])
    expect(html.index("clipboard-text-param")).to be < html.index("[template]")
    expect(html.index("[template]")).to be < html.index("[notification]")
  end

  context "with a Steam announcement" do
    let(:event_type) { "Integrations::Steam::AnnouncementPublished" }

    it "adds the author" do
      expect(chips).to eq(%w[game author feed title])
    end
  end

  context "with Twitch" do
    let(:plugin_key) { :twitch }
    let(:subscription) { build(:feed_subscription, :twitch) }

    context "with a highlight" do
      let(:event_type) { "Integrations::Twitch::HighlightPublished" }

      it "offers neither the category nor the clipper" do
        expect(chips).to eq(%w[streamer title])
      end
    end

    context "with a clip" do
      let(:event_type) { "Integrations::Twitch::ClipCreated" }

      it "offers the clipper" do
        expect(chips).to eq(%w[streamer category title clipper])
      end
    end
  end
end
