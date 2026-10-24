# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::CustomMessageField do
  include_context "component view context"

  subject(:html) { described_class.new(subscription:, plugin_key: :steam_news, event_type:).render_in(view_context) }

  let(:event_type) { "Integrations::Steam::PatchNotesPublished" }
  let(:subscription) { build(:feed_subscription, watch: build(:integration_watch, name: "Hades II")) }
  let(:template) { "{role} Hot take: {title}" }

  before { subscription.subscribed_events.build(event_type:, template:) }

  it "renders the textarea with the stored text and the default as placeholder" do
    expect(html).to include('name="subscription[templates][Integrations::Steam::PatchNotesPublished]"')
    expect(html).to include(">{role} Hot take: {title}</textarea>")
    expect(html).to include(%(placeholder="#{Feeds::Templates.default(event_type)}"))
  end

  it "renders one copy chip per token" do
    Feeds::Templates::TOKENS_BY_SOURCE.fetch(:steam_news).each do |token|
      expect(html).to include(%(data-clipboard-text-param="{#{token}}"))
    end
  end

  it "renders the preview output and sample tokens for the controller" do
    expect(html).to include('data-feed-preview-target="output"', "data-feed-preview-field", "Hades II", "Patch 1.4")
  end

  context "when the type is not followed" do
    let(:subscription) { build(:feed_subscription, watch: build(:integration_watch)) }

    before { subscription.subscribed_events.clear }

    it "leaves the textarea empty" do
      expect(html).to include("></textarea>")
    end
  end
end
