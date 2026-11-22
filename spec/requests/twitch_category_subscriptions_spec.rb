# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Twitch category follows", type: :request do
  include_context "plugin config request"

  let(:plugin_path) { new_server_twitch_category_subscription_path(guild.id) }
  let(:list_path) { server_twitch_path(guild.id, tab: "twitch_category") }
  let(:live) { "Integrations::Twitch::StreamStarted" }
  let(:picked) { Feeds::Twitch::CategoryValue.dump({"id" => "32982", "name" => "Grand Theft Auto V"}) }
  let(:target) { Integrations::Target.new(external_id: "32982", name: "Grand Theft Auto V", image_url: "https://static-cdn.jtvnw.net/ttv-boxart/gta.jpg", url: "https://www.twitch.tv/directory/game/Grand%20Theft%20Auto%20V") }
  let!(:twitch_plugin) { create(:plugin, key: "twitch", name: "Twitch") }
  let(:page) { Nokogiri::HTML(response.body) }

  before do
    post "/auth/discord/callback"
    create(:server_configuration, discord_id: guild.id)
    create(:plugin_activation, server_configuration: config, plugin: twitch_plugin, enabled: true)
    create(:server_channel, server_configuration: config, discord_id: 777, name: "streams")
    create(:server_role, server_configuration: config, discord_id: 555, name: "Follow pings")
    allow(Bot::Discord::UserGuilds).to receive(:call).and_return([guild])
    allow(Integrations::Twitch::CategoryWatcher).to receive(:resolve).with("32982").and_return(target)
    allow(Integrations::Twitch::CategoryWatcher).to receive(:refresh).with(["32982"]).and_return([target])
    get server_path(guild.id)
  end

  describe "GET /servers/:server_id/twitch/category-follows/new" do
    subject(:lookup) { get plugin_path, params: {category: input} }

    let(:input) { picked }

    context "without a pick" do
      let(:input) { nil }

      it "renders the picker, which searches Twitch's categories" do
        lookup

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Add a category", "Look up")
        expect(response.body).not_to include("translation missing")
        expect(page.at_css("select[name=category]")["data-tom-select-search-url-value"]).to eq(server_twitch_categories_path(guild.id))
        expect(page.at_css("input[type=text][name=category]")).to be_nil
      end
    end

    {
      Integrations::InvalidReference => "That doesn&#39;t look like a Twitch category.",
      Integrations::NotFound => "Twitch has no such category.",
      Integrations::Unavailable => "Twitch didn&#39;t answer."
    }.each do |error_class, message|
      context "when the lookup raises #{error_class}" do
        before { allow(Integrations::Twitch::CategoryWatcher).to receive(:resolve).with("32982").and_raise(error_class) }

        it "shows the message and keeps the pick" do
          lookup

          expect(response.body).to include(message)
          expect(response.body).not_to include("translation missing")
          expect(page.css("select[name=category] option[selected]").map(&:text)).to eq(["Grand Theft Auto V"])
        end
      end
    end

    context "with a pick that is not a picked category" do
      let(:input) { "32982" }

      it "hands the text to the watcher as it is" do
        lookup

        expect(response.body).to include("Follow Grand Theft Auto V")
      end
    end

    context "when the pick is forged into a list" do
      subject(:lookup) { get plugin_path, params: {category: ["x"]} }

      before { allow(Integrations::Twitch::CategoryWatcher).to receive(:resolve).and_call_original }

      it "refuses it as not a category" do
        lookup

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("That doesn&#39;t look like a Twitch category.")
      end
    end

    context "when Twitch resolves the category" do
      it "renders the follow form with its one post type off and the filters" do
        lookup

        expect(response.body).to include("Grand Theft Auto V", "Follow Grand Theft Auto V", "Not this one?", "100 most-watched streams")
        expect(response.body).not_to include("translation missing")
        expect(page.at_css(%(input[type=checkbox][name="subscription[event_types][#{live}]"]))["checked"]).to be_nil
        expect(page.css("input[type=checkbox][name^='subscription[event_types]']").size).to eq(1)
      end

      it "has one role for the follow, no per-type role, and every filter" do
        lookup

        expect(page.css(%(select[name="subscription[role_id]"])).size).to eq(1)
        expect(page.css(%(select[name*="_role_id"]))).to be_empty
        expect(page.css(%(input[name="subscription[min_viewers]"]))).to be_one
        expect(page.css(%(select[name="subscription[languages][]"]))).to be_one
        expect(page.css(%(select[name="subscription[excluded_channels][]"]))).to be_one
        expect(page.css(%(input[name="subscription[live_end_mode]"]))).to be_one
        expect(page.css(%(input[name="subscription[switched_away]"]))).to be_one
      end
    end

    context "when the server follows as many categories as it can" do
      before { create_list(:feed_subscription, Feeds::TwitchCategory.max_follows, :twitch_category, server_configuration: config) }

      it "sends the admin back to the categories tab with the reason" do
        lookup

        expect(response).to redirect_to(list_path)
        expect(flash[:alert]).to eq(Feeds::Subscription.cap_message(Feeds::TwitchCategory))
      end
    end
  end

  describe "POST /servers/:server_id/twitch/category-follows" do
    subject(:create_subscription) { post server_twitch_category_subscriptions_path(guild.id), params: {subscription: attributes} }

    let(:attributes) do
      {
        external_id: "32982",
        channel_id: "777",
        role_id: "555",
        min_viewers: "50",
        languages: ["", "de", "en"],
        excluded_channels: ["", "@Some_Streamer", "https://twitch.tv/Other", "some_streamer"],
        live_end_mode: "keep",
        switched_away: "delete",
        show_viewers: "0",
        show_preview_frame: "0",
        event_types: {live => "1"}
      }
    end

    it "follows the category with its filters normalised and returns to the categories tab" do
      create_subscription

      expect(response).to redirect_to(list_path)
      expect(flash[:notice]).to eq("Now following Grand Theft Auto V.")
      subscription = config.feed_subscriptions.sole
      expect(subscription.twitch_category_settings).to have_attributes(
        role_id: 555,
        min_viewers: 50,
        languages: %w[de en],
        excluded_channels: %w[some_streamer other],
        live_end_mode: "keep",
        switched_away: "delete",
        show_viewers: false,
        show_preview_frame: false
      )
      expect(subscription.subscribed_events.map(&:event_type)).to eq([live])
    end

    context "with a language the settings do not know" do
      before { attributes[:languages] = ["English"] }

      it "renders the form again with the reason and writes nothing" do
        expect { create_subscription }.not_to change(Feeds::Subscription, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Follow Grand Theft Auto V")
      end
    end

    context "with a floor below zero" do
      before { attributes[:min_viewers] = "-1" }

      it "renders the form again and writes nothing" do
        expect { create_subscription }.not_to change(Feeds::Subscription, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with a role from another server" do
      before { attributes[:role_id] = "999" }

      it "responds not found and writes nothing" do
        expect { create_subscription }.not_to change(Feeds::Subscription, :count)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the server follows as many categories as it can" do
      before { create_list(:feed_subscription, Feeds::TwitchCategory.max_follows, :twitch_category, server_configuration: config) }

      it "refuses with the reason and writes nothing" do
        expect { create_subscription }.not_to change(Feeds::Subscription, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(Feeds::Subscription.cap_message(Feeds::TwitchCategory))
      end
    end

    context "when Twitch is down" do
      before { allow(Integrations::Twitch::CategoryWatcher).to receive(:refresh).and_raise(Integrations::Unavailable) }

      it "renders the lookup with the error and writes nothing" do
        expect { create_subscription }.not_to change(Feeds::Subscription, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Twitch didn&#39;t answer.")
      end
    end
  end

  describe "GET /servers/:server_id/twitch/category-follows/:id/edit" do
    subject(:edit) { get edit_server_twitch_category_subscription_path(guild.id, subscription) }

    let!(:subscription) { create(:feed_subscription, :twitch_category, server_configuration: config, channel_id: 777) }

    before do
      subscription.watch.update!(url: "https://www.twitch.tv/directory/game/Hades")
      subscription.settings.update!(role_id: 555, min_viewers: 30, languages: %w[de], excluded_channels: %w[loud_one], switched_away: "delete")
      create(:feed_subscribed_event, subscription:, event_type: live)
    end

    it "renders the form with the stored settings and a confirmed stop-following button" do
      edit

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("This deletes your settings for this category.")
      expect(response.body).not_to include("translation missing")
      expect(page.at_css(%(select[name="subscription[role_id]"] option[selected]))["value"]).to eq("555")
      expect(page.at_css(%(input[name="subscription[min_viewers]"]))["value"]).to eq("30")
      expect(page.css(%(select[name="subscription[languages][]"] option[selected])).map(&:text)).to eq(["German"])
      expect(page.css(%(select[name="subscription[excluded_channels][]"] option[selected])).map(&:text)).to eq(["loud_one"])
      expect(page.at_css(%(input[name="subscription[switched_away]"]))["value"]).to eq("delete")
      expect(page.at_css(%(input[type=checkbox][name="subscription[event_types][#{live}]"]))["checked"]).to be_present
    end

    it "links out to the category and back to the categories tab" do
      edit

      expect(page.at_css(%(a[href="https://www.twitch.tv/directory/game/Hades"][target="_blank"]))).to be_present
      expect(page.at_css(%(a[href="#{list_path}"]))).to be_present
    end

    context "when the follow belongs to another server" do
      let!(:subscription) { create(:feed_subscription, :twitch_category) }

      it "responds not found" do
        edit

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /servers/:server_id/twitch/category-follows/:id" do
    subject(:update) do
      patch(
        server_twitch_category_subscription_path(guild.id, subscription),
        params: {subscription: {channel_id: "777", min_viewers: "0", languages: [""], excluded_channels: ["", "NewOne"], live_end_mode: "keep", event_types: {live => "1"}}},
        **turbo
      )
    end

    let!(:subscription) { create(:feed_subscription, :twitch_category, server_configuration: config, channel_id: 555) }

    before { subscription.settings.update!(min_viewers: 100, languages: %w[de], excluded_channels: %w[old_one]) }

    it "saves, clears the emptied list and re-renders the form as a turbo stream" do
      update

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("twitch_category-config")
      expect(subscription.reload).to have_attributes(channel_id: 777)
      expect(subscription.twitch_category_settings).to have_attributes(min_viewers: 0, languages: [], excluded_channels: %w[newone], live_end_mode: "keep")
    end

    context "when the follow belongs to another server" do
      let!(:subscription) { create(:feed_subscription, :twitch_category) }

      it "responds not found and changes nothing" do
        update

        expect(response).to have_http_status(:not_found)
        expect(subscription.reload.channel_id).to eq(555_000)
      end
    end
  end

  describe "DELETE /servers/:server_id/twitch/category-follows/:id" do
    subject(:destroy) { delete server_twitch_category_subscription_path(guild.id, subscription) }

    let!(:subscription) { create(:feed_subscription, :twitch_category, server_configuration: config) }

    it "stops following and returns to the categories tab" do
      expect { destroy }.to change(Feeds::Subscription, :count).by(-1)

      expect(response).to redirect_to(list_path)
      expect(flash[:notice]).to eq("Stopped following #{subscription.watch.name}.")
    end

    context "when the follow belongs to another server" do
      let!(:subscription) { create(:feed_subscription, :twitch_category) }

      it "responds not found and keeps it" do
        expect { destroy }.not_to change(Feeds::Subscription, :count)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
