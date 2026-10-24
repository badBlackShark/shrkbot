# frozen_string_literal: true

class Servers::SteamNews::SubscriptionsController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin
  include VerifiesGuildChannels
  include VerifiesGuildRoles

  WATCHER = Integrations::Steam::NewsWatcher

  before_action :load_subscription, only: [:edit, :update, :destroy]

  def new
    return redirect_to steam_news_path, alert: cap_message if ::Feeds::Subscription.at_cap?(@server_configuration)
    return render_lookup if params[:app].blank?

    lookup = ::Feeds::TargetLookup.call(WATCHER, params[:app])
    return render_lookup(input: params[:app], error: lookup.error) if lookup.error

    existing = followed_subscription(lookup.target)
    return render_lookup(input: params[:app], existing:) if existing

    render_new(subscription: build_subscription(lookup.target, {body_length: "preview"}, ::Feeds::DEFAULT_EVENT_TYPES_BY_SOURCE.fetch(plugin_key)), target: lookup.target)
  end

  def create
    return head :not_found unless guild_channels?(subscription_params[:channel_id]) && guild_roles?(subscription_params[:role_id])

    lookup = ::Feeds::TargetLookup.call(WATCHER, subscription_params[:external_id])
    return render_lookup(input: subscription_params[:external_id], error: lookup.error, status: :unprocessable_content) if lookup.error

    result = Ops::Feeds::Subscriptions::Create.call(
      server_configuration: @server_configuration,
      watcher: WATCHER.name,
      target: lookup.target,
      channel_id: subscription_params[:channel_id],
      role_id: subscription_params[:role_id],
      body_length: subscription_params[:body_length],
      event_types:,
      templates:
    )
    return redirect_to steam_news_path, notice: t("servers.steam_news.followed", name: lookup.target.name) if result.success?

    render_new(
      subscription: result.value || build_subscription(lookup.target, subscription_params.slice(:channel_id, :role_id, :body_length), event_types, templates:),
      target: lookup.target,
      error: result.errors.to_sentence,
      status: :unprocessable_content
    )
  end

  def edit
    render Views::Servers::SteamNews::Subscriptions::Edit.new(
      server_configuration: @server_configuration,
      user: current_user,
      subscription: @subscription
    )
  end

  def update
    return head :not_found unless guild_channels?(subscription_params[:channel_id]) && guild_roles?(subscription_params[:role_id])

    result = Ops::Feeds::Subscriptions::Update.call(
      subscription: @subscription,
      channel_id: subscription_params[:channel_id],
      role_id: subscription_params[:role_id],
      body_length: subscription_params[:body_length],
      event_types:,
      templates:
    )
    @error = result.errors.to_sentence if result.failure?
    respond_with_save(result)
  end

  def destroy
    Ops::Feeds::Subscriptions::Destroy.call(subscription: @subscription)
    redirect_to steam_news_path, notice: t("servers.steam_news.unfollowed", name: @subscription.watch.name), status: :see_other
  end

  private

  def plugin_key
    :steam_news
  end

  def load_subscription
    @subscription = source_subscriptions.find_by(id: params[:id])
    head :not_found unless @subscription
  end

  def source_subscriptions
    Finders::Feeds::SourceSubscriptions.call(server_configuration: @server_configuration, plugin_key:)
  end

  def followed_subscription(target)
    source_subscriptions.find_by(integration_watches: {external_id: target.external_id})
  end

  def build_subscription(target, attributes, event_types, templates: {})
    @server_configuration.feed_subscriptions.build(attributes.merge(watch: unsaved_watch(target))).tap do |subscription|
      event_types.each do |event_type|
        subscription.subscribed_events.build(
          event_type:,
          template: ::Feeds::Templates.custom(event_type, templates[event_type])
        )
      end
    end
  end

  def unsaved_watch(target)
    ::Integrations::Watch.new(watcher: WATCHER.name, external_id: target.external_id, name: target.name, image_url: target.image_url)
  end

  def render_lookup(input: nil, error: nil, existing: nil, status: :ok)
    render Views::Servers::SteamNews::Subscriptions::Lookup.new(
      server_configuration: @server_configuration,
      user: current_user,
      input:,
      error:,
      existing:
    ), status:
  end

  def render_new(subscription:, target:, error: nil, status: :ok)
    render Views::Servers::SteamNews::Subscriptions::New.new(
      server_configuration: @server_configuration,
      user: current_user,
      subscription:,
      target:,
      error:,
      volume: ::Feeds::VolumeLookup.call(WATCHER, target.external_id)
    ), status:
  end

  def steam_news_path
    server_steam_news_path(params[:server_id])
  end

  def cap_message
    t("operations.feeds.subscriptions.cap", max: ::Feeds::Subscription::MAX_PER_SERVER)
  end

  def configuration_url
    edit_server_steam_news_subscription_path(params[:server_id], @subscription)
  end

  def event_types
    subscription_params[:event_types].to_h.filter_map { |event_type, value| event_type if value == "1" }
  end

  def templates
    subscription_params[:templates].to_h
  end

  def subscription_params
    @subscription_params ||= params.expect(subscription: [:external_id, :channel_id, :role_id, :body_length, event_types: {}, templates: {}])
  end
end
