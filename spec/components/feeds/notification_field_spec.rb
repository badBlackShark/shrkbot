# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::NotificationField do
  include_context "component view context"

  subject(:html) { described_class.new(subscription:, plugin_key: :steam, event_type:, event:).render_in(view_context) }

  let(:event_type) { "Integrations::Steam::PatchNotesPublished" }
  let(:subscription) { build(:feed_subscription, watch: build(:integration_watch, name: "Hades II")) }
  let(:notification_template) { nil }

  let(:event) { subscription.subscribed_events.build(event_type:, notification_template:) }

  it "prefills the source default when nothing is stored" do
    expect(html).to include('name="subscription[notifications][Integrations::Steam::PatchNotesPublished]"')
    expect(html).to include(">{game} · Patch notes: {title}</textarea>")
  end

  context "with a stored text" do
    let(:notification_template) { "Out now: {title}" }

    it "shows the stored text" do
      expect(html).to include(">Out now: {title}</textarea>")
    end
  end

  context "when the type is not followed" do
    let(:event) { nil }

    it "still prefills the default" do
      expect(html).to include(">{game} · Patch notes: {title}</textarea>")
    end
  end

  it "offers the title chip beside game, author and feed" do
    chips = html.scan(/data-clipboard-text-param="\{(\w+)\}"/).flatten
    expect(chips).to eq(%w[game author feed title])
  end

  it "renders the preview output and the sample tokens for the controller" do
    expect(html).to include('data-feed-preview-target="output"', "data-feed-preview-field", "Hades II", "Patch 1.4")
  end
end
