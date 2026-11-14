# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Twitch subscriptions", type: :request do
  include_context "plugin config request"

  let(:plugin_path) { new_server_twitch_subscription_path(guild.id) }
  let(:list_path) { server_twitch_path(guild.id) }
  let(:live) { "Integrations::Twitch::StreamStarted" }
  let(:highlights) { "Integrations::Twitch::HighlightPublished" }
  let(:uploads) { "Integrations::Twitch::UploadPublished" }
  let(:featured_clips) { "Integrations::Twitch::FeaturedClipPublished" }
  let(:clips) { "Integrations::Twitch::ClipCreated" }
  let(:target) { Integrations::Target.new(external_id: "9001", name: "SomeStreamer", image_url: "https://static-cdn.jtvnw.net/profile.png", url: "https://www.twitch.tv/somestreamer") }
  let!(:integrations_plugin) { create(:plugin, key: "integrations", name: "Integrations") }
  let!(:twitch_plugin) { create(:plugin, key: "twitch", name: "Twitch") }

  before do
    post "/auth/discord/callback"
    create(:server_configuration, discord_id: guild.id)
    create(:plugin_activation, server_configuration: config, plugin: integrations_plugin, enabled: true)
    create(:plugin_activation, server_configuration: config, plugin: twitch_plugin, enabled: true)
    create(:server_channel, server_configuration: config, discord_id: 777, name: "streams")
    create(:server_role, server_configuration: config, discord_id: 888, name: "Live pings")
    allow(Bot::Discord::UserGuilds).to receive(:call).and_return([guild])
    allow(Integrations::Twitch::ChannelWatcher).to receive(:resolve).with("somestreamer").and_return(target)
    allow(Integrations::Twitch::ChannelWatcher).to receive(:refresh).with(["9001"]).and_return([target])
    get server_path(guild.id)
  end

  def checkbox(type)
    Nokogiri::HTML(response.body).at_css(%(input[type=checkbox][name="subscription[event_types][#{type}]"]))
  end

  describe "GET /servers/:server_id/twitch/subscriptions/new" do
    subject(:lookup) { get plugin_path, params: {channel: input} }

    let(:input) { "somestreamer" }

    context "without an input" do
      let(:input) { nil }

      it "renders the empty lookup" do
        lookup

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Add a channel", "Paste a link to the channel on Twitch", "Look up")
        expect(response.body).not_to include("translation missing")
      end
    end

    {
      Integrations::InvalidReference => "That doesn&#39;t look like a Twitch channel.",
      Integrations::NotFound => "Twitch has no channel with that name.",
      Integrations::Unavailable => "Twitch didn&#39;t answer."
    }.each do |error_class, message|
      context "when the lookup raises #{error_class}" do
        let(:input) { "nobody" }

        before { allow(Integrations::Twitch::ChannelWatcher).to receive(:resolve).with("nobody").and_raise(error_class) }

        it "shows the message inline and keeps the input" do
          lookup

          expect(response.body).to include(message, "aria-invalid=\"true\"", "nobody")
          expect(response.body).not_to include("translation missing")
        end
      end
    end

    context "when Twitch resolves the channel" do
      it "renders the follow form with the five post types, all off" do
        lookup

        expect(response.body).to include("SomeStreamer", "Follow SomeStreamer", "Not this one?")
        expect(response.body).not_to include("translation missing")
        expect([live, highlights, uploads, featured_clips, clips].map { |type| checkbox(type) }).to all(be_present)
        expect([live, highlights, uploads, featured_clips, clips].map { |type| checkbox(type)["checked"] }).to all(be_nil)
      end

      it "renders one role select per post type and the end mode only for live" do
        lookup

        page = Nokogiri::HTML(response.body)
        names = %w[live_role_id highlights_role_id uploads_role_id featured_clips_role_id clips_role_id].map { |column| %(select[name="subscription[#{column}]"]) }
        expect(names.map { |selector| page.css(selector).size }).to all(eq(1))
        expect(page.css(%(input[name="subscription[live_end_mode]"]))).to be_one
        expect(page.css(%(input[type=checkbox][name="subscription[show_viewers]"]))).to be_one
      end
    end
  end

  describe "POST /servers/:server_id/twitch/subscriptions" do
    subject(:create_subscription) { post server_twitch_subscriptions_path(guild.id), params: {subscription: attributes} }

    let(:channel_id) { "777" }
    let(:live_role_id) { "888" }
    let(:clips_role_id) { "" }
    let(:category_values) { [Feeds::Twitch::CategoryValue.dump({"id" => "1", "name" => "Hades II"}), "garbage", "[1]"] }
    let(:attributes) do
      {
        external_id: "9001",
        channel_id:,
        live_role_id:,
        highlights_role_id: "",
        uploads_role_id: "",
        featured_clips_role_id: "",
        clips_role_id:,
        live_end_mode: "delete",
        show_viewers: "0",
        switched_away: "delete",
        categories: ["", *category_values],
        event_types: {live => "1", highlights => "1", clips => "0"},
        choices: {live => {template: " Go watch "}}
      }
    end

    it "follows the channel with its per-type roles, end mode and viewer setting" do
      create_subscription

      expect(response).to redirect_to(list_path)
      expect(flash[:notice]).to eq("Now following SomeStreamer.")
      expect(config.feed_subscriptions.sole.twitch_settings).to have_attributes(
        live_role_id: 888,
        highlights_role_id: nil,
        live_end_mode: "delete",
        show_viewers: false,
        switched_away: "delete",
        categories: [{"id" => "1", "name" => "Hades II"}]
      )
      expect(config.feed_subscriptions.sole.subscribed_events.map(&:event_type)).to match_array([live, highlights])
    end

    context "with more categories than the bound" do
      let(:category_values) { Array.new(Feeds::Twitch::Settings::MAX_CATEGORIES + 1) { |index| Feeds::Twitch::CategoryValue.dump({"id" => index.to_s, "name" => "Game #{index}"}) } }

      it "renders the form again with the reason and writes nothing" do
        expect { create_subscription }.not_to change(Feeds::Subscription, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Twitch settings categories can have at most 100 categories")
      end
    end

    context "with a category whose id is not a string" do
      let(:category_values) { [Feeds::Twitch::CategoryValue.dump({"id" => "1", "name" => "Hades II"}), '{"id":1,"name":"x"}'] }

      it "drops it and saves the rest" do
        create_subscription

        expect(config.feed_subscriptions.sole.twitch_settings.categories).to eq([{"id" => "1", "name" => "Hades II"}])
      end
    end

    context "with no categories" do
      let(:category_values) { [] }

      it "stores an empty list" do
        create_subscription

        expect(config.feed_subscriptions.sole.twitch_settings.categories).to eq([])
      end
    end

    context "with a role from another server on a role column that is not live" do
      let(:live_role_id) { "" }
      let(:clips_role_id) { "999" }

      it "responds not found and writes nothing" do
        expect { create_subscription }.not_to change(Feeds::Subscription, :count)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with a channel for one post type" do
      let(:channels) { {live => "777", highlights => ""} }

      before { attributes[:choices] = attributes[:choices].deep_merge(channels.transform_values { |id| {channel_id: id} }) }

      it "saves it on that type only" do
        create_subscription

        stored = config.feed_subscriptions.sole.subscribed_events.to_h { |event| [event.event_type, event.channel_id] }
        expect(stored).to eq(live => 777, highlights => nil)
      end

      context "when the channel is from another server" do
        let(:channels) { {live => "999"} }

        it "responds not found and writes nothing" do
          expect { create_subscription }.not_to change(Feeds::Subscription, :count)

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "with a channel from another server" do
      let(:channel_id) { "999" }

      it "responds not found and writes nothing" do
        expect { create_subscription }.not_to change(Feeds::Subscription, :count)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when Twitch is down" do
      before { allow(Integrations::Twitch::ChannelWatcher).to receive(:refresh).and_raise(Integrations::Unavailable) }

      it "renders an empty lookup with the error, never the numeric id as a name, and writes nothing" do
        expect { create_subscription }.not_to change(Feeds::Subscription, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Twitch didn&#39;t answer.")
        expect(response.body).not_to include('value="9001"')
      end
    end

    context "when the channel is left empty" do
      let(:channel_id) { "" }

      it "renders the form again with the reason and keeps what was entered" do
        expect { create_subscription }.not_to change(Feeds::Subscription, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Channel can&#39;t be blank", "Follow SomeStreamer")
        expect(response.body).not_to include("translation missing")
        expect(checkbox(highlights)["checked"]).to be_present
        expect(checkbox(clips)["checked"]).to be_nil
      end
    end
  end

  describe "GET /servers/:server_id/twitch" do
    let!(:subscription) { create(:feed_subscription, :twitch, server_configuration: config) }

    it "lists the followed channel" do
      get list_path

      expect(response.body).to include(subscription.watch.name, "Followed channels")
      expect(response.body).not_to include("translation missing")
    end
  end

  describe "GET /servers/:server_id/twitch/subscriptions/:id/edit" do
    subject(:edit) { get edit_server_twitch_subscription_path(guild.id, subscription) }

    let!(:subscription) { create(:feed_subscription, :twitch, server_configuration: config, channel_id: 777) }

    before do
      subscription.watch.update!(url: "https://www.twitch.tv/somestreamer")
      subscription.settings.update!(live_role_id: 888, live_end_mode: "keep", switched_away: "delete", categories: [{"id" => "1", "name" => "Hades II"}])
      create(:feed_subscribed_event, subscription:, event_type: live)
    end

    it "renders the form with the stored settings and a confirmed stop-following button" do
      edit

      page = Nokogiri::HTML(response.body)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("This deletes your settings for this channel.")
      expect(response.body).not_to include("translation missing")
      expect(page.at_css(%(select[name="subscription[live_role_id]"] option[selected]))["value"]).to eq("888")
      expect(page.at_css(%(input[name="subscription[live_end_mode]"]))["value"]).to eq("keep")
      expect(page.at_css(%(input[name="subscription[switched_away]"]))["value"]).to eq("delete")
      expect(page.css(%(select[name="subscription[categories][]"] option[selected])).map(&:text)).to eq(["Hades II"])
      expect(checkbox(live)["checked"]).to be_present
    end

    it "links out to the channel instead of offering to pick another" do
      edit

      page = Nokogiri::HTML(response.body)
      expect(page.at_css(%(a[href="https://www.twitch.tv/somestreamer"][target="_blank"]))).to be_present
      expect(response.body).not_to include("Not this one?")
    end
  end

  describe "PATCH /servers/:server_id/twitch/subscriptions/:id" do
    subject(:update) do
      patch(
        server_twitch_subscription_path(guild.id, subscription),
        params: {subscription: {channel_id: "777", live_end_mode: "mark_ended", show_viewers:, categories:, event_types: {live => "1"}, choices:}},
        **turbo
      )
    end

    let(:show_viewers) { "0" }
    let(:categories) { [""] }
    let(:channels) { {live => ""} }
    let(:choices) { channels.transform_values { |id| {channel_id: id} } }
    let!(:subscription) { create(:feed_subscription, :twitch, server_configuration: config, channel_id: 555) }

    context "with a forged value in place of a post type's choices" do
      let(:choices) { {live => "forged"} }

      it "treats the type as having no choices and saves" do
        update

        expect(response).to have_http_status(:ok)
        expect(subscription.reload.subscribed_events.sole).to have_attributes(event_type: live, channel_id: nil)
      end
    end

    it "saves and re-renders the form as a turbo stream" do
      update

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("twitch-config")
      expect(subscription.reload).to have_attributes(channel_id: 777)
      expect(subscription.twitch_settings).to have_attributes(live_end_mode: "mark_ended", show_viewers: false)
    end

    context "with a post type channel of this server" do
      let(:channels) { {live => "777"} }

      it "stores it on that post type" do
        update

        expect(subscription.reload.subscribed_events.sole).to have_attributes(event_type: live, channel_id: 777)
      end
    end

    context "with a post type channel from another server" do
      let(:channels) { {live => "999"} }

      it "responds not found and changes nothing" do
        update

        expect(response).to have_http_status(:not_found)
        expect(subscription.reload).to have_attributes(channel_id: 555)
        expect(subscription.subscribed_events).to be_empty
      end
    end

    context "when every chosen category is cleared" do
      before { subscription.settings.update!(categories: [{"id" => "1", "name" => "Hades II"}]) }

      it "stores an empty list" do
        update

        expect(subscription.reload.twitch_settings.categories).to eq([])
      end
    end

    context "when categories are chosen" do
      let(:categories) { ["", Feeds::Twitch::CategoryValue.dump({"id" => "2", "name" => "Just Chatting"})] }

      it "replaces the stored list" do
        update

        expect(subscription.reload.twitch_settings.categories).to eq([{"id" => "2", "name" => "Just Chatting"}])
      end
    end

    context "when the viewer count is switched on" do
      let(:show_viewers) { "1" }

      before { subscription.settings.update!(show_viewers: false) }

      it "stores true" do
        update

        expect(subscription.reload.twitch_settings.show_viewers).to be(true)
      end
    end
  end

  describe "DELETE /servers/:server_id/twitch/subscriptions/:id" do
    subject(:destroy) { delete server_twitch_subscription_path(guild.id, subscription) }

    let!(:subscription) { create(:feed_subscription, :twitch, server_configuration: config) }

    it "stops following and redirects to the list" do
      expect { destroy }.to change(Feeds::Subscription, :count).by(-1)

      expect(response).to redirect_to(list_path)
      expect(flash[:notice]).to eq("Stopped following #{subscription.watch.name}.")
    end
  end
end
