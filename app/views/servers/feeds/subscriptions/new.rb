# frozen_string_literal: true

class Views::Servers::Feeds::Subscriptions::New < Views::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(source:, server_configuration:, user:, subscription:, target:, error: nil)
    @source = source
    @config = server_configuration
    @user = user
    @subscription = subscription
    @target = target
    @error = error
  end

  def view_template
    render Components::PluginShell.new(user: @user, server_configuration: @config, active_key: @source.plugin_key) do
      render Components::Feeds::AddPage.new(server_configuration: @config, source: @source) do
        render Components::Feeds::TargetCard.new(target: @target, source: @source) do
          render Components::Feeds::TargetChangeLink.new(href: ::Feeds::SubscriptionPaths.new_for(@config, @source))
        end
        follow_form
      end
    end
  end

  private

  def follow_form
    form_with(url: ::Feeds::SubscriptionPaths.collection_for(@config, @source), class: "mt-5 flex flex-col gap-5") do
      input(type: "hidden", name: "subscription[external_id]", value: @target.external_id)
      render Components::Feeds::SubscriptionForm.new(subscription: @subscription, source: @source, error: @error)
      actions
    end
  end

  def actions
    div(class: "flex justify-end gap-3") do
      render Components::Button.new(
        variant: :ghost,
        label: t(".cancel"),
        href: ::Feeds::SubscriptionPaths.plugin_for(@config, @source)
      )
      render Components::Button.new(label: t(".follow", name: @target.name), type: "submit")
    end
  end
end
