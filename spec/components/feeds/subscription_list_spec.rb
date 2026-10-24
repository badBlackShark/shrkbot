# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::SubscriptionList do
  include_context "component view context"

  subject(:html) { described_class.new(server_configuration:, plugin_key: :steam_news).render_in(view_context) }

  let(:server_configuration) { create(:server_configuration) }
  let(:add_path) { Rails.application.routes.url_helpers.new_server_steam_news_subscription_path(server_configuration.discord_id) }

  context "with room left" do
    before { create(:feed_subscription, server_configuration:) }

    it "links Add a game to the lookup page" do
      expect(html).to include(%(href="#{add_path}"))
      expect(html).not_to include("feed-subscriptions-cap")
    end
  end

  context "at the cap" do
    before { create_list(:feed_subscription, Feeds::Subscription::MAX_PER_SERVER, server_configuration:) }

    it "disables Add a game and points it at the reason" do
      expect(html).not_to include(add_path)
      expect(html).to include("disabled", 'aria-describedby="feed-subscriptions-cap"', 'id="feed-subscriptions-cap"')
    end
  end

  context "with no games" do
    it "puts the Add button in the empty state" do
      expect(html).to include("No games yet", add_path)
    end
  end
end
