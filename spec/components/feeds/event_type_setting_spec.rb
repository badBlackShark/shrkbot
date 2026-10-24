# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::EventTypeSetting do
  include_context "component view context"

  subject(:html) do
    described_class.new(subscription:, plugin_key: :steam_news, event_type:, followed: true, volume:).render_in(view_context)
  end

  let(:subscription) { build(:feed_subscription, watch: build(:integration_watch, name: "Hades II")) }
  let(:event_type) { "Integrations::Steam::PatchNotesPublished" }
  let(:volume) { Integrations::Volume.new(counts: {event_type => 2}, sample_size: 20) }

  it "wires the toggle to sync the disclosure" do
    expect(html).to include('data-action="change->disclosure#sync"')
  end

  it "keys the remembered disclosure by subscription and type" do
    expect(html).to include('data-disclosure-key-value="feeds-message-new-patch_notes_published"')
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
