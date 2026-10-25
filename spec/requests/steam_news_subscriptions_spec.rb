# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Steam News subscriptions", type: :request do
  include_context "plugin config request"

  let(:plugin_path) { new_server_steam_news_subscription_path(guild.id) }
  let(:list_path) { server_steam_news_path(guild.id) }
  let(:patch_notes) { "Integrations::Steam::PatchNotesPublished" }
  let(:announcements) { "Integrations::Steam::AnnouncementPublished" }
  let(:articles) { "Integrations::Steam::ArticlePublished" }
  let(:target) { Integrations::Target.new(external_id: "1145350", name: "Hades II", image_url: "https://shared.akamai.steamstatic.com/hades.jpg") }
  let!(:feeds_plugin) { create(:plugin, key: "feeds", name: "Feeds") }
  let!(:steam_news_plugin) { create(:plugin, key: "steam_news", name: "Steam News") }

  before do
    post "/auth/discord/callback"
    create(:server_configuration, discord_id: guild.id)
    create(:plugin_activation, server_configuration: config, plugin: feeds_plugin, enabled: true)
    create(:plugin_activation, server_configuration: config, plugin: steam_news_plugin, enabled: true)
    create(:server_channel, server_configuration: config, discord_id: 777, name: "news")
    create(:server_role, server_configuration: config, discord_id: 888, name: "Gamers")
    allow(Bot::Discord::UserGuilds).to receive(:call).and_return([guild])
    allow(Integrations::Steam::NewsWatcher).to receive(:resolve).with("1145350").and_return(target)
    allow(Integrations::Steam::NewsWatcher).to receive(:volume).and_return(Integrations::Volume.new(counts: {}, sample_size: 20))
    get server_path(guild.id)
  end

  def checkbox(type)
    Nokogiri::HTML(response.body).at_css(%(input[type=checkbox][name="subscription[event_types][#{type}]"]))
  end

  describe "GET /servers/:server_id/steam_news/subscriptions/new" do
    subject(:lookup) { get plugin_path, params: {app: input} }

    let(:input) { "1145350" }

    context "without an input" do
      let(:input) { nil }

      it "renders the empty lookup" do
        lookup

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Steam link or app ID", "Look up")
        expect(response.body).not_to include("aria-invalid=\"true\"")
      end
    end

    {
      Integrations::InvalidReference => "That doesn&#39;t look like a Steam link.",
      Integrations::NotFound => "Steam has no app with that ID.",
      Integrations::Unavailable => "Steam didn&#39;t answer."
    }.each do |error_class, message|
      context "when the lookup raises #{error_class}" do
        let(:input) { "hades" }

        before { allow(Integrations::Steam::NewsWatcher).to receive(:resolve).with("hades").and_raise(error_class) }

        it "shows the message inline and keeps the input" do
          lookup

          expect(response).to have_http_status(:ok)
          expect(response.body).to include(message, "aria-invalid=\"true\"", "hades")
        end
      end
    end

    context "when the server already follows the game" do
      let!(:subscription) do
        create(:feed_subscription, server_configuration: config, watch: create(:integration_watch, external_id: "1145350", name: "Hades II"))
      end

      it "links to that subscription's edit page" do
        lookup

        expect(response.body).to include("This server already follows Hades II.")
        expect(response.body).to include(edit_server_steam_news_subscription_path(guild.id, subscription))
      end
    end

    context "when the server is at the cap" do
      before { create_list(:feed_subscription, Feeds::Subscription::MAX_PER_SERVER, server_configuration: config) }

      it "redirects to the list with the cap as the alert" do
        lookup

        expect(response).to redirect_to(list_path)
        expect(flash[:alert]).to eq("This server follows 25 games, the most it can. Stop following one to add another.")
      end
    end

    context "when Steam resolves the game" do
      it "renders the follow form with the default post types" do
        lookup

        expect(response.body).to include("Hades II", "Steam app 1145350", "Follow Hades II")
        expect(checkbox(patch_notes)["checked"]).to be_present
        expect(checkbox(announcements)["checked"]).to be_present
        expect(checkbox(articles)["checked"]).to be_nil
      end

      it "shows how many of the last posts were each type" do
        lookup

        expect(response.body).to include("None of the last 20 posts.")
      end

      context "when the last posts included some of a type" do
        before do
          allow(Integrations::Steam::NewsWatcher).to receive(:volume)
            .and_return(Integrations::Volume.new(counts: {patch_notes => 2}, sample_size: 20))
        end

        it "shows the count on that type" do
          lookup

          expect(response.body).to include("2 of the last 20 posts.")
        end
      end

      context "when the volume lookup fails" do
        before { allow(Feeds::VolumeLookup).to receive(:call).and_return(nil) }

        it "renders the form without hints" do
          lookup

          expect(response).to have_http_status(:ok)
          expect(response.body).not_to include("of the last")
        end
      end
    end
  end

  describe "POST /servers/:server_id/steam_news/subscriptions" do
    subject(:create_subscription) { post server_steam_news_subscriptions_path(guild.id), params: {subscription: attributes} }

    let(:channel_id) { "777" }
    let(:role_id) { "888" }
    let(:attributes) do
      {
        external_id: "1145350",
        channel_id:,
        role_id:,
        body_length: "full",
        event_types: {patch_notes => "1", announcements => "0", articles => "1"},
        templates: {patch_notes => " Patch day: {title} ", articles => "{feed}: {title}"}
      }
    end

    let(:stored_templates) { config.feed_subscriptions.sole.subscribed_events.to_h { |event| [event.event_type, event.template] } }

    it "follows the game and redirects to the list" do
      create_subscription

      expect(response).to redirect_to(list_path)
      expect(flash[:notice]).to eq("Now following Hades II.")
      expect(config.feed_subscriptions.sole).to have_attributes(channel_id: 777, role_id: 888, body_length: "full")
      expect(config.feed_subscriptions.sole.subscribed_events.map(&:event_type)).to match_array([patch_notes, articles])
      expect(config.feed_subscriptions.sole.watch).to have_attributes(name: "Hades II", image_url: target.image_url)
    end

    it "stores custom text and nothing for the default text" do
      create_subscription

      expect(stored_templates).to eq(patch_notes => "Patch day: {title}", articles => nil)
    end

    context "with the untouched default text" do
      let(:attributes) do
        super().merge(
          event_types: {patch_notes => "1"},
          templates: {patch_notes => Feeds::Templates.default(patch_notes)}
        )
      end

      it "follows with the default and stores nothing" do
        create_subscription

        expect(stored_templates).to eq(patch_notes => nil)
      end
    end

    context "with a post type that is not one of the source's" do
      let(:attributes) do
        super().merge(
          event_types: {"Other::Thing" => "1", patch_notes => "1"},
          templates: {"Other::Thing" => "x"}
        )
      end

      it "follows only the source's types" do
        create_subscription

        expect(response).to redirect_to(list_path)
        expect(config.feed_subscriptions.sole.subscribed_events.map(&:event_type)).to eq([patch_notes])
      end
    end

    context "with a message that would post nothing" do
      let(:role_id) { "" }
      let(:attributes) { super().merge(templates: {patch_notes => "{author}"}) }

      it "renders the form again with the reason and writes nothing" do
        expect { create_subscription }.not_to change(Feeds::Subscription, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("A custom message needs some text besides placeholders that can be empty")
      end
    end

    context "with a channel from another server" do
      let(:channel_id) { "999" }

      it "responds not found and writes nothing" do
        expect { create_subscription }.not_to change(Feeds::Subscription, :count)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with a role from another server" do
      let(:role_id) { "999" }

      it "responds not found and writes nothing" do
        expect { create_subscription }.not_to change(Feeds::Subscription, :count)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when Steam is down" do
      before { allow(Integrations::Steam::NewsWatcher).to receive(:resolve).and_raise(Integrations::Unavailable) }

      it "renders the lookup with the error and writes nothing" do
        expect { create_subscription }.not_to change(Feeds::Subscription, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Steam didn&#39;t answer.")
      end
    end

    context "when the channel is left empty" do
      let(:channel_id) { "" }

      it "renders the form again with the reason and keeps what was entered" do
        expect { create_subscription }.not_to change(Feeds::Subscription, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Channel can&#39;t be blank", "Follow Hades II")
        expect(checkbox(articles)["checked"]).to be_present
        expect(checkbox(announcements)["checked"]).to be_nil
      end
    end
  end

  describe "GET /servers/:server_id/steam_news/subscriptions/:id/edit" do
    subject(:edit) { get edit_server_steam_news_subscription_path(guild.id, subscription) }

    let(:watch) { create(:integration_watch, name: "Hades II", external_id: "1145350") }
    let!(:subscription) { create(:feed_subscription, server_configuration: config, watch:, channel_id: 777) }

    before { create(:feed_subscribed_event, subscription:, event_type: patch_notes, template: "Hot take: {title}") }

    it "shows the stored template in its textarea" do
      edit

      textarea = Nokogiri::HTML(response.body).at_css(%(textarea[name="subscription[templates][#{patch_notes}]"]))
      expect(textarea.text).to eq("Hot take: {title}")
    end

    it "shows the default text for a post type without a custom template" do
      edit

      textarea = Nokogiri::HTML(response.body).at_css(%(textarea[name="subscription[templates][#{announcements}]"]))
      expect(textarea.text).to eq(Feeds::Templates.default(announcements))
    end

    it "renders the form with the stored settings and a confirmed stop-following button" do
      edit

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Hades II", "Steam app 1145350", "Stop following Hades II?")
      expect(checkbox(patch_notes)["checked"]).to be_present
      expect(checkbox(articles)["checked"]).to be_nil
    end

    context "when the last posts included some of a type" do
      before do
        allow(Integrations::Steam::NewsWatcher).to receive(:volume)
          .and_return(Integrations::Volume.new(counts: {patch_notes => 2}, sample_size: 20))
      end

      it "shows the count on that type" do
        edit

        expect(response.body).to include("2 of the last 20 posts.")
      end
    end

    it "offers one stop-following button named after the game" do
      edit

      expect(response.body).to include("Stop following Hades II")
      expect(response.body).not_to include("No more posts for this game")
    end

    context "when the subscription belongs to another server" do
      let!(:subscription) { create(:feed_subscription, watch:) }

      it "responds not found" do
        edit

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /servers/:server_id/steam_news/subscriptions/:id" do
    subject(:update) do
      patch(
        server_steam_news_subscription_path(guild.id, subscription),
        params: {subscription: {channel_id:, role_id: "", body_length: "full", event_types:, templates:}},
        **headers
      )
    end

    let(:headers) { turbo }
    let(:channel_id) { "777" }
    let(:event_types) { {patch_notes => "1", announcements => "1"} }
    let(:templates) { {patch_notes => "Patch day: {title}"} }
    let(:followed_since) { 3.days.ago.change(usec: 0) }
    let!(:subscription) { create(:feed_subscription, server_configuration: config, channel_id: 555) }

    before { create(:feed_subscribed_event, subscription:, event_type: patch_notes, subscribed_since: followed_since) }

    it "saves, keeps the followed type's follow time and re-renders the form" do
      update

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("steam_news-config")
      expect(subscription.reload).to have_attributes(channel_id: 777, body_length: "full")
      expect(subscription.subscribed_events.find_by!(event_type: patch_notes).subscribed_since).to eq(followed_since)
      expect(subscription.subscribed_events.map(&:event_type)).to match_array([patch_notes, announcements])
    end

    it "stores the submitted custom text" do
      update

      expect(subscription.subscribed_events.find_by!(event_type: patch_notes).template).to eq("Patch day: {title}")
    end

    context "with a message that would post nothing" do
      let(:templates) { {patch_notes => "{author}"} }

      it "re-renders the form with the reason and changes nothing" do
        update

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("A custom message needs some text besides placeholders that can be empty")
        expect(subscription.subscribed_events.find_by!(event_type: patch_notes).template).to be_nil
      end
    end

    context "when the channel is cleared" do
      let(:channel_id) { "" }

      it "re-renders the form with the reason and changes nothing" do
        update

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Channel can&#39;t be blank")
        expect(subscription.reload).to have_attributes(channel_id: 555, body_length: "preview")
      end

      context "when a followed post type is unchecked with a draft message" do
        let(:event_types) { {announcements => "1"} }
        let(:templates) { {patch_notes => "Draft survives: {title}"} }

        it "re-renders the draft in that type's textarea" do
          update

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include(">Draft survives: {title}</textarea>")
        end
      end

      context "when a followed post type is unchecked" do
        let(:event_types) { {announcements => "1"} }

        it "re-renders the type as unchecked and keeps it followed in the database" do
          update

          expect(response).to have_http_status(:unprocessable_content)
          expect(checkbox(patch_notes)["checked"]).to be_nil
          expect(checkbox(announcements)["checked"]).to be_present
          expect(subscription.subscribed_events.reload.map(&:event_type)).to eq([patch_notes])
        end
      end
    end

    context "without a Turbo Stream" do
      let(:headers) { {} }

      it "redirects back to the edit page" do
        update

        expect(response).to redirect_to(edit_server_steam_news_subscription_path(guild.id, subscription))
        expect(flash[:notice]).to eq("Steam News settings saved.")
      end
    end

    context "with a channel from another server" do
      subject(:update) do
        patch server_steam_news_subscription_path(guild.id, subscription), params: {subscription: {channel_id: "999", event_types: {}}}
      end

      it "responds not found and changes nothing" do
        update

        expect(response).to have_http_status(:not_found)
        expect(subscription.reload.channel_id).to eq(555)
      end
    end
  end

  describe "DELETE /servers/:server_id/steam_news/subscriptions/:id" do
    subject(:destroy) { delete server_steam_news_subscription_path(guild.id, subscription) }

    let!(:subscription) { create(:feed_subscription, server_configuration: config, watch: create(:integration_watch, name: "Hades II")) }

    it "stops following and redirects to the list" do
      expect { destroy }.to change(Feeds::Subscription, :count).by(-1)

      expect(response).to redirect_to(list_path)
      expect(response).to have_http_status(:see_other)
      expect(flash[:notice]).to eq("Stopped following Hades II.")
    end

    context "when the subscription belongs to another server" do
      let!(:subscription) { create(:feed_subscription) }

      it "responds not found and keeps it" do
        expect { destroy }.not_to change(Feeds::Subscription, :count)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
