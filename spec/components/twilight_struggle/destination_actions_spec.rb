# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::TwilightStruggle::DestinationActions do
  include Rails.application.routes.url_helpers

  include_context "component view context"

  subject(:html) do
    described_class.new(tournament:, destination:, server_configuration:, channel_label:).render_in(view_context)
  end

  let(:server_configuration) { create(:server_configuration) }
  let(:tournament) { create(:twilight_struggle_tournament) }
  let(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:) }
  let(:channel_label) { nil }

  it "links to the tournament's settings" do
    expect(html).to include(edit_server_twilight_struggle_destination_path(server_configuration.discord_id, tournament))
  end

  it "offers unsubscribing behind a confirmation" do
    expect(html).to include(I18n.t("components.twilight_struggle.destination_actions.unsubscribe"))
    expect(html).to include("data-turbo-method=\"delete\"")
    expect(html).to include(I18n.t("components.twilight_struggle.destination_actions.unsubscribe_confirm"))
  end

  it "says nothing about a channel while none is picked" do
    expect(html).not_to include("Tournaments")
  end

  context "when the destination posts to a known channel" do
    let(:channel_label) { "Tournaments / #results" }

    it "names the channel under its category" do
      expect(html).to include("Tournaments / #results")
    end
  end

  context "when the server does not subscribe to the tournament" do
    let(:destination) { nil }

    it "offers subscribing instead of unsubscribing" do
      expect(html).to include(server_twilight_struggle_destinations_path(server_configuration.discord_id, tournament_id: tournament.id))
      expect(html).to include("data-turbo-method=\"post\"")
    end

    it "still links to the tournament's settings, so it can be set up first" do
      expect(html).to include(edit_server_twilight_struggle_destination_path(server_configuration.discord_id, tournament))
    end
  end
end
