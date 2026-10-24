# frozen_string_literal: true

class Views::Servers::SteamNews::Subscriptions::Lookup < Views::Base
  include Phlex::Rails::Helpers::FormWith

  FIELD = "w-full rounded-control border-[1.5px] border-border-strong bg-surface-card px-3 py-2 font-mono text-sm " \
    "text-text-primary placeholder:text-text-secondary focus:border-accent focus:outline-none " \
    "focus:ring-3 focus:ring-[var(--focus-ring)] aria-invalid:border-danger"
  ERROR_ID = "steam-news-lookup-error"

  def initialize(server_configuration:, user:, input: nil, error: nil, existing: nil)
    @config = server_configuration
    @user = user
    @input = input
    @error = error
    @existing = existing
  end

  def view_template
    render Components::PluginShell.new(user: @user, server_configuration: @config, active_key: :steam_news) do
      render Components::Feeds::AddPage.new(server_configuration: @config, plugin_key: :steam_news) do
        render Components::PageHeading.new(title: t(".title"), subtitle: t(".subtitle"))
        render Components::Card.new { lookup_form }
      end
    end
  end

  private

  def lookup_form
    form_with(url: new_server_steam_news_subscription_path(@config.discord_id), method: :get, class: "flex flex-col gap-3") do
      render Components::FieldLabel.new { t(".label") }
      input(
        type: "text",
        name: "app",
        value: @input,
        class: FIELD,
        autofocus: true,
        autocomplete: "off",
        aria_invalid: problem?.to_s,
        aria_describedby: (ERROR_ID if problem?)
      )
      problem_message
      div(class: "flex justify-end") { render Components::Button.new(label: t(".submit"), type: "submit") }
    end
  end

  def problem?
    @error.present? || @existing.present?
  end

  def problem_message
    if @existing
      existing_message
    elsif @error
      p(id: ERROR_ID, class: "text-sm text-danger") { t(".errors.#{@error}") }
    end
  end

  def existing_message
    p(id: ERROR_ID, class: "text-sm text-text-secondary") do
      plain t("operations.feeds.subscriptions.already_followed", name: @existing.watch.name)
      plain " "
      a(href: edit_server_steam_news_subscription_path(@config.discord_id, @existing), class: "text-accent-soft-fg underline") { t(".edit_existing") }
    end
  end
end
