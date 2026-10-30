# frozen_string_literal: true

class Servers::Steam::SubscriptionsController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin
  include VerifiesGuildChannels
  include VerifiesGuildRoles

  WATCHER = ::Integrations::Steam::NewsWatcher

  before_action :load_subscription, only: [:edit, :update, :destroy]

  def new
    return redirect_to steam_path, alert: ::Feeds::Subscription.cap_message(source) if ::Feeds::Subscription.at_cap?(@server_configuration, source)
    return render_lookup if params[:app].blank?

    lookup = ::Feeds::TargetLookup.call(WATCHER, params[:app])
    return render_lookup(input: params[:app], error: lookup.error) if lookup.error

    existing = followed_subscription(lookup.target)
    return render_lookup(input: params[:app], existing:) if existing

    render_new(subscription: build_subscription(lookup.target, source.default_event_types), target: lookup.target)
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
      settings:,
      event_types:,
      templates:
    )
    return redirect_to steam_path, notice: t("servers.steam.followed", name: lookup.target.name) if result.success?

    render_new(
      subscription: result.value || build_subscription(lookup.target, event_types, channel_id: subscription_params[:channel_id], settings:, templates:),
      target: lookup.target,
      error: result.errors.to_sentence,
      status: :unprocessable_content
    )
  end

  def edit
    render Views::Servers::Steam::Subscriptions::Edit.new(
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
      settings:,
      event_types:,
      templates:
    )
    @error = result.errors.to_sentence if result.failure?
    respond_with_save(result)
  end

  def destroy
    Ops::Feeds::Subscriptions::Destroy.call(subscription: @subscription)
    redirect_to steam_path, notice: t("servers.steam.unfollowed", name: @subscription.watch.name), status: :see_other
  end

  private

  def plugin_key
    :steam
  end

  def source
    ::Feeds.source(plugin_key)
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

  def build_subscription(target, event_types, channel_id: nil, settings: {}, templates: {})
    @server_configuration.feed_subscriptions.build(watch: unsaved_watch(target), channel_id:).tap do |subscription|
      subscription.build_settings(settings)
      event_types.each { |event_type| subscription.follow(event_type, templates[event_type]) }
    end
  end

  def unsaved_watch(target)
    ::Integrations::Watch.new(watcher: WATCHER.name, external_id: target.external_id, name: target.name, image_url: target.image_url)
  end

  def render_lookup(input: nil, error: nil, existing: nil, status: :ok)
    render Views::Servers::Steam::Subscriptions::Lookup.new(
      server_configuration: @server_configuration,
      user: current_user,
      input:,
      error:,
      existing:
    ), status:
  end

  def render_new(subscription:, target:, error: nil, status: :ok)
    render Views::Servers::Steam::Subscriptions::New.new(
      server_configuration: @server_configuration,
      user: current_user,
      subscription:,
      target:,
      error:
    ), status:
  end

  def steam_path
    server_steam_path(params[:server_id])
  end

  def configuration_url
    edit_server_steam_subscription_path(params[:server_id], @subscription)
  end

  def event_types
    submitted = subscription_params[:event_types].to_h
    source.event_types.select { |event_type| submitted[event_type] == "1" }
  end

  def templates
    subscription_params[:templates].to_h
  end

  def settings
    {role_id: subscription_params[:role_id], body_length: subscription_params[:body_length], languages:}
  end

  def languages
    Array(subscription_params[:languages])
  end

  def subscription_params
    @subscription_params ||= params.expect(subscription: [:external_id, :channel_id, :role_id, :body_length, languages: [], event_types: {}, templates: {}])
  end
end
