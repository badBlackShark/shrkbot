# frozen_string_literal: true

class Servers::Feeds::SubscriptionsController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin
  include VerifiesGuildChannels
  include VerifiesGuildRoles

  before_action :load_subscription, only: [:edit, :update, :destroy]

  def new
    return redirect_to plugin_path, alert: ::Feeds::Subscription.cap_message(source) if ::Feeds::Subscription.at_cap?(@server_configuration, source)
    return render_lookup if params[lookup_param].blank?

    lookup = ::Feeds::TargetLookup.call(watcher_class, params[lookup_param])
    return render_lookup(input: params[lookup_param], error: lookup.error) if lookup.error

    existing = followed_subscription(lookup.target)
    return render_lookup(input: params[lookup_param], existing:) if existing

    render_new(subscription: build_subscription(lookup.target, source.default_event_types), target: lookup.target)
  end

  def create
    return head :not_found unless guild_channels?(subscription_params[:channel_id]) && guild_roles?(*role_ids)

    lookup = ::Feeds::TargetLookup.call(watcher_class, subscription_params[:external_id])
    return render_lookup(input: subscription_params[:external_id], error: lookup.error, status: :unprocessable_content) if lookup.error

    result = Ops::Feeds::Subscriptions::Create.call(
      server_configuration: @server_configuration,
      watcher: watcher_class.name,
      target: lookup.target,
      channel_id: subscription_params[:channel_id],
      settings:,
      event_types:,
      templates:
    )
    return redirect_to plugin_path, notice: t("servers.#{plugin_key}.followed", name: lookup.target.name) if result.success?

    render_new(
      subscription: result.value || build_subscription(lookup.target, event_types, channel_id: subscription_params[:channel_id], settings:, templates:),
      target: lookup.target,
      error: result.errors.to_sentence,
      status: :unprocessable_content
    )
  end

  def edit
    render Views::Servers::Feeds::Subscriptions::Edit.new(
      plugin_key:,
      server_configuration: @server_configuration,
      user: current_user,
      subscription: @subscription
    )
  end

  def update
    return head :not_found unless guild_channels?(subscription_params[:channel_id]) && guild_roles?(*role_ids)

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
    redirect_to plugin_path, notice: t("servers.#{plugin_key}.unfollowed", name: @subscription.watch.name), status: :see_other
  end

  private

  def watcher_class
    source.watchers.sole.constantize
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
    ::Integrations::Watch.new(watcher: watcher_class.name, external_id: target.external_id, name: target.name, image_url: target.image_url)
  end

  def render_lookup(input: nil, error: nil, existing: nil, status: :ok)
    render Views::Servers::Feeds::Subscriptions::Lookup.new(
      plugin_key:,
      lookup_param:,
      server_configuration: @server_configuration,
      user: current_user,
      input:,
      error:,
      existing:
    ), status:
  end

  def render_new(subscription:, target:, error: nil, status: :ok)
    render Views::Servers::Feeds::Subscriptions::New.new(
      plugin_key:,
      server_configuration: @server_configuration,
      user: current_user,
      subscription:,
      target:,
      error:
    ), status:
  end

  def plugin_path
    PluginPaths.for(@server_configuration, plugin_key)
  end

  def configuration_url
    ::Feeds::SubscriptionPaths.edit_for(@subscription)
  end

  def event_types
    submitted = subscription_params[:event_types].to_h
    source.event_types.select { |event_type| submitted[event_type] == "1" }
  end

  def templates
    subscription_params[:templates].to_h
  end

  def subscription_params
    @subscription_params ||= params.expect(subscription: [:external_id, :channel_id, *settings_params, {event_types: {}, templates: {}}])
  end
end
