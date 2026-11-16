# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::EventTypeSetting do
  include_context "component view context"

  subject(:html) do
    described_class.new(subscription:, plugin_key:, event_type:, event:, **extra).render_in(view_context)
  end

  let(:plugin_key) { :steam }
  let(:extra) { {} }

  let(:subscription) { build(:feed_subscription, watch: build(:integration_watch, name: "Hades II", external_id: "1145350")) }
  let(:event_type) { "Integrations::Steam::PatchNotesPublished" }
  let(:event) { subscription.subscribed_events.build(event_type:) }

  let(:document) { Nokogiri::HTML.fragment(html) }
  let(:card) { document.element_children.first }
  let(:details) { card.at_css("details") }
  let(:header) { details.at_css("summary") }
  let(:body) { details.element_children.last }

  it "is the card, scoped to its own type" do
    expect(card).to have_attribute("data-feed-preview-scope")
  end

  it "is a disclosure that remembers its open state per type" do
    expect(details["data-controller"]).to eq("disclosure")
    expect(details["data-disclosure-key-value"]).to eq("feeds-message-1145350-patch_notes_published")
    expect(details).not_to have_attribute("open")
  end

  it "shows the type's help line" do
    expect(html).to include("Posts the developer tagged as patch notes.")
  end

  it "wires the checked toggle to open and close the card" do
    toggle = header.at_css("input[type=checkbox]")

    expect(toggle.attributes.keys).to include("data-type-toggle", "checked")
    expect(toggle["data-action"]).to eq("change->disclosure#follow")
  end

  it "folds from anywhere in the header, and not from the settings below it" do
    expect(header["data-action"]).to eq("click->disclosure#toggle")
    expect(header.at_css(".dropdown-chevron")).to be_present
    expect(body.name).to eq("div")
    expect(body.at_css("[data-action*='disclosure#toggle']")).to be_nil
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
      expect(html).to include("subscription[choices][#{event_type}][template]")
    end
  end

  it "orders the body: channel override, message, push text" do
    expect(body.css("select, textarea").map { |field| field["name"] }).to eq(
      ["subscription[choices][#{event_type}][channel_id]", "subscription[choices][#{event_type}][template]", "subscription[choices][#{event_type}][notification]"]
    )
    expect(body.text).to include("Channel override")
    expect(body.to_html).to include("Same as above")
  end

  it "lists the placeholders once" do
    expect(html.scan(/data-clipboard-text-param="\{(\w+)\}"/).flatten).to eq(%w[game feed title])
  end

  context "with a channel of its own" do
    let(:event) { subscription.subscribed_events.build(event_type:, channel_id: 111) }

    before do
      create(:server_channel, server_configuration: subscription.server_configuration, discord_id: 111, name: "clips")
    end

    it "selects it in the type's channel field" do
      select = Nokogiri::HTML.fragment(html).at_css(%(select[name="subscription[choices][#{event_type}][channel_id]"]))

      expect(select.at_css("option[selected]")["value"]).to eq("111")
    end
  end

  context "with a source that has per-type fields" do
    let(:plugin_key) { :twitch }
    let(:event_type) { "Integrations::Twitch::HighlightPublished" }
    let(:subscription) { build(:feed_subscription, :twitch) }
    let(:extra) { {type_fields: Components::Feeds::Twitch::TypeFields} }

    it "renders them in the body before the text fields" do
      expect(body.css("select, textarea").map { |field| field["name"] }).to eq(
        ["subscription[choices][#{event_type}][channel_id]", "subscription[highlights_role_id]", "subscription[choices][#{event_type}][template]", "subscription[choices][#{event_type}][notification]"]
      )
    end

    it "shows no help line for the type" do
      expect(html).not_to include("When the streamer saves part of a past stream")
      expect(html).to include("New highlight")
    end

    context "with the live type" do
      let(:event_type) { "Integrations::Twitch::StreamStarted" }

      it "puts the notification text before the end mode" do
        expect(html.index("[notification]")).to be < html.index("live_end_mode")
      end
    end

    context "with all clips" do
      let(:event_type) { "Integrations::Twitch::ClipCreated" }

      it "puts the volume warning in the header, outside the body" do
        expect(body.text).not_to include("dozens to hundreds of clips")
        expect(html).to include("Big channels get dozens to hundreds of clips per stream, and each one is a post.")
      end
    end

    context "with featured clips" do
      let(:event_type) { "Integrations::Twitch::FeaturedClipPublished" }

      it "puts the 48-hour note in the header, outside the body" do
        expect(body.text).not_to include("48 hours")
        expect(html).to include("Only clips featured within 48 hours of being made get posted.")
      end
    end
  end
end
