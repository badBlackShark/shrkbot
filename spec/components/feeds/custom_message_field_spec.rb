# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::CustomMessageField do
  include_context "component view context"

  subject(:html) { described_class.new(subscription:, plugin_key: :steam, event_type:, event:).render_in(view_context) }

  let(:event_type) { "Integrations::Steam::PatchNotesPublished" }
  let(:subscription) { build(:feed_subscription, watch: build(:integration_watch, name: "Hades II")) }
  let(:template) { "Hot take: {game}" }

  let(:event) { subscription.subscribed_events.build(event_type:, template:) }

  it "renders the textarea with the stored text and the hint as placeholder" do
    expect(html).to include('name="subscription[templates][Integrations::Steam::PatchNotesPublished]"')
    expect(html).to include(">Hot take: {game}</textarea>")
    expect(html).to include('placeholder="Shown above the card. Leave it empty to post the card alone."')
  end

  it "renders one copy chip per token, and only game, author and feed" do
    chips = html.scan(/data-clipboard-text-param="\{(\w+)\}"/).flatten
    expect(chips).to eq(%w[game author feed])
  end

  it "offers no role placeholder" do
    expect(html).not_to include("{role}")
  end

  it "renders the preview output, the eyebrow and the sample tokens for the controller" do
    expect(html).to include('data-feed-preview-target="output"', "data-feed-preview-field", "Hades II", "Hades II · Patch notes", "Patch 1.4")
  end

  context "when the type is not followed" do
    let(:event) { nil }

    it "leaves the textarea empty" do
      expect(html).to include("></textarea>")
    end
  end
end
