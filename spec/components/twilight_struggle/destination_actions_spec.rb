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

  it "offers unsubscribing, with no confirmation to click through since nothing is lost" do
    expect(html).to include(I18n.t("components.twilight_struggle.destination_actions.unsubscribe"))
    expect(html).to include(server_twilight_struggle_subscription_path(server_configuration.discord_id, tournament))
    expect(html).to include("data-turbo-method=\"delete\"")
    expect(html).not_to include("turbo-confirm")
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

  context "when the server unsubscribed but kept its settings" do
    let(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:, active: false, discord_channel_id: 4242) }
    let(:channel_label) { "Tournaments / #results" }

    it "offers subscribing again" do
      expect(html).to include(server_twilight_struggle_subscriptions_path(server_configuration.discord_id, tournament_id: tournament.id))
    end

    it "does not advertise a channel it is not posting to" do
      expect(html).not_to include("Tournaments / #results")
    end
  end

  context "when the server does not subscribe to the tournament" do
    let(:destination) { nil }

    it "offers subscribing instead of unsubscribing" do
      expect(html).to include(server_twilight_struggle_subscriptions_path(server_configuration.discord_id, tournament_id: tournament.id))
      expect(html).to include("data-turbo-method=\"post\"")
    end

    it "still links to the tournament's settings, so it can be set up first" do
      expect(html).to include(edit_server_twilight_struggle_destination_path(server_configuration.discord_id, tournament))
    end
  end
end
