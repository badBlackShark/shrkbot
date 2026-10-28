# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::EventTypeSetting do
  include_context "component view context"

  subject(:html) do
    described_class.new(subscription:, plugin_key: :steam, event_type:, event:).render_in(view_context)
  end

  let(:subscription) { build(:feed_subscription, watch: build(:integration_watch, name: "Hades II", external_id: "1145350")) }
  let(:event_type) { "Integrations::Steam::PatchNotesPublished" }
  let(:event) { subscription.subscribed_events.build(event_type:) }

  it "wires the toggle to sync the disclosure" do
    expect(html).to include('data-action="change->disclosure#sync"')
  end

  it "keys the remembered disclosure by game and type" do
    expect(html).to include('data-disclosure-key-value="feeds-message-1145350-patch_notes_published"')
  end

  it "lets the disclosure read the toggle, which is on for a followed type" do
    expect(html).to include('data-disclosure-target="toggle"').and match(/ checked[ >=]/)
  end

  context "when the type is not followed" do
    let(:event) { nil }

    it "leaves the toggle off" do
      expect(html).not_to match(/ checked[ >=]/)
    end
  end

  context "when the follow is marked for removal" do
    before { event.mark_for_destruction }

    it "leaves the toggle off but keeps the draft text field" do
      expect(html).not_to match(/ checked[ >=]/)
      expect(html).to include("subscription[templates][#{event_type}]")
    end
  end

  it "shows the custom message field inside the disclosure" do
    expect(html).to include('data-disclosure-target="details"', "Custom message", "subscription[templates][#{event_type}]")
  end
end
