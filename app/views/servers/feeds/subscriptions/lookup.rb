# frozen_string_literal: true

class Views::Servers::Feeds::Subscriptions::Lookup < Views::Base
  include Phlex::Rails::Helpers::FormWith

  ERROR_ID = "feed-lookup-error"

  def initialize(source:, lookup_param:, server_configuration:, user:, input: nil, error: nil, existing: nil)
    @source = source
    @lookup_param = lookup_param
    @config = server_configuration
    @user = user
    @input = input
    @error = error
    @existing = existing
  end

  def view_template
    render Components::PluginShell.new(user: @user, server_configuration: @config, active_key: @source.plugin_key) do
      render Components::Feeds::AddPage.new(server_configuration: @config, source: @source) do
        render Components::PageHeading.new(title: t(".#{@source.key}.title"))
        render Components::Card.new { lookup_form }
      end
    end
  end

  private

  def lookup_form
    form_with(url: ::Feeds::SubscriptionPaths.new_for(@config, @source), method: :get, class: "flex flex-col gap-3") do
      render Components::FieldLabel.new { t(".#{@source.key}.label") }
      render lookup_field.new(name: @lookup_param, value: @input, server_configuration: @config, error_id: (ERROR_ID if problem?))
      problem_message
      div(class: "flex justify-end") { render Components::Button.new(label: t(".submit"), type: "submit") }
    end
  end

  def lookup_field
    "Components::Feeds::#{@source.key.to_s.camelize}::LookupField".safe_constantize || Components::Feeds::LookupTextField
  end

  def problem?
    @error.present? || @existing.present?
  end

  def problem_message
    if @existing
      existing_message
    elsif @error
      p(id: ERROR_ID, class: "text-sm text-danger-text") { t(".#{@source.key}.errors.#{@error}") }
    end
  end

  def existing_message
    p(id: ERROR_ID, class: "text-sm text-text-secondary") do
      plain t("operations.feeds.subscriptions.already_followed", name: @existing.watch.name)
      plain " "
      a(href: ::Feeds::SubscriptionPaths.edit_for(@existing), class: "text-accent-soft-fg underline") { t(".edit_existing") }
    end
  end
end
