# frozen_string_literal: true

RSpec.shared_context "with a stream moving between followed categories" do
  let(:server_configuration) { create(:server_configuration) }
  let(:session) { "9001" }
  let(:story_key) { "stream:#{session}" }
  let(:stream_watch) { create(:integration_watch, :twitch, state: {"session" => session}) }
  let(:watch_a) { create(:integration_watch, :twitch_category, external_id: "cat-a") }
  let(:watch_b) { create(:integration_watch, :twitch_category, external_id: "cat-b") }
  let(:channel_b) { 555_000 }
  let!(:follow_a) { create(:feed_subscription, :twitch_category, :active, server_configuration:, watch: watch_a, channel_id: 555_000) }
  let!(:follow_b) { create(:feed_subscription, :twitch_category, :active, server_configuration:, watch: watch_b, channel_id: channel_b) }
  let!(:started_in_a) { create(:twitch_stream_started_event, watch: stream_watch, session:, category_id: "cat-a", occurred_at: 20.minutes.ago) }
  let!(:updated_to_b) { create(:twitch_stream_updated_event, watch: stream_watch, session:, category_id: "cat-b", category_name: "Elsewhere", occurred_at: Time.current) }
  let!(:card_of_a) { create(:feed_post, subscription: follow_a, story_key:, channel_id: 555_000, message_id: 777_000) }

  before do
    [follow_a, follow_b].each do |follow|
      create(:feed_subscribed_event, subscription: follow, event_type: "Integrations::Twitch::StreamStarted", subscribed_since: 1.day.ago)
    end
    allow(Feeds::Twitch::LiveImage).to receive(:for).and_return(nil)
    allow(Bot::Discord::Components).to receive(:edit)
    allow(Bot::Discord::Components).to receive(:delete_message)
    allow(Bot::Discord::Components).to receive(:create_with_subject).and_return(888_000)
  end
end
