# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::EventTypeSetting do
  include_context "component view context"

  subject(:html) do
    described_class.new(subscription:, plugin_key: :steam_news, event_type:, event:, volume:).render_in(view_context)
  end

  let(:subscription) { build(:feed_subscription, watch: build(:integration_watch, name: "Hades II", external_id: "1145350")) }
  let(:event_type) { "Integrations::Steam::PatchNotesPublished" }
  let(:event) { subscription.subscribed_events.build(event_type:) }
  let(:volume) { Integrations::Volume.new(counts: {event_type => 2}, sample_size: 20) }

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

  it "appends the volume hint to the type's help" do
    expect(html).to include("2 of the last 20 posts.")
  end

  context "when none of the sample was this type" do
    let(:volume) { Integrations::Volume.new(counts: {}, sample_size: 20) }

    it "says none" do
      expect(html).to include("None of the last 20 posts.")
    end
  end

  context "when exactly one was" do
    let(:volume) { Integrations::Volume.new(counts: {event_type => 1}, sample_size: 20) }

    it "uses the singular" do
      expect(html).to include("1 of the last 20 posts.")
    end
  end

  context "without a volume" do
    let(:volume) { nil }

    it "shows no hint" do
      expect(html).not_to include("of the last")
    end
  end

  context "with an empty sample" do
    let(:volume) { Integrations::Volume.new(counts: {}, sample_size: 0) }

    it "shows no hint" do
      expect(html).not_to include("of the last")
    end
  end
end
