# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::TwilightStruggle::DestinationActions do
  include Rails.application.routes.url_helpers

  include_context "component view context"

  subject(:html) { described_class.new(destination:, channel_label:).render_in(view_context) }

  let(:server_configuration) { create(:server_configuration) }
  let(:tournament) { create(:twilight_struggle_tournament) }
  let(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:) }
  let(:channel_label) { nil }

  it "links to the destination's settings" do
    expect(html).to include(edit_server_twilight_struggle_destination_path(server_configuration.discord_id, destination))
  end

  it "offers unsubscribing behind a confirmation" do
    expect(html).to include(I18n.t("components.twilight_struggle.destination_actions.unsubscribe"))
    expect(html).to include("data-turbo-method=\"delete\"")
    expect(html).to include(I18n.t("components.twilight_struggle.destination_actions.unsubscribe_confirm"))
  end

  it "says nothing about a channel while none is picked" do
    expect(html).not_to include("text-sm text-text-secondary")
  end

  context "when the destination posts to a known channel" do
    let(:channel_label) { "results" }

    it "names the channel" do
      expect(html).to include("results")
    end
  end
end
