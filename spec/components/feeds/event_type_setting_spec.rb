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

  it "scopes the viewer-count preview switch to its own type" do
    expect(html).to start_with('<div class="group/type"')
  end

  it "shows the type's help line" do
    expect(html).to include("Posts the developer tagged as patch notes.")
  end

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
      expect(html).to include("subscription[choices][#{event_type}][template]")
    end
  end

  it "shows the custom message field inside the disclosure" do
    expect(html).to include('data-disclosure-target="details"', "Settings", "subscription[choices][#{event_type}][template]")
  end

  it "puts the type's channel before the message fields" do
    names = Nokogiri::HTML.fragment(html).css("select, textarea").map { |field| field["name"] }

    expect(names.first).to eq("subscription[choices][#{event_type}][channel_id]")
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

  it "scopes the role pill of its fields to itself" do
    root = Nokogiri::HTML.fragment(html).at_css("[data-controller=disclosure]")
    expect(root.attributes).to have_key("data-feed-preview-scope")
  end

  context "with a source that has per-type fields" do
    let(:plugin_key) { :twitch }
    let(:event_type) { "Integrations::Twitch::HighlightPublished" }
    let(:subscription) { build(:feed_subscription, :twitch) }
    let(:extra) { {type_fields: Components::Feeds::Twitch::TypeFields} }

    it "renders them inside the disclosure before the text fields, under a settings summary" do
      details = Nokogiri::HTML.fragment(html).at_css("[data-disclosure-target=details]")

      expect(details.at_css("summary").text).to include("Settings")
      expect(details.css("select, textarea").map { |field| field["name"] }).to eq(
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
  end
end
