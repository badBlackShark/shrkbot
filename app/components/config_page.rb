# frozen_string_literal: true

class Components::ConfigPage < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(header:, server_configuration:, url:, toggle: nil, prerequisites: nil, channel_lost: false, parent_crumb: nil)
    @header = header
    @server_configuration = server_configuration
    @url = url
    @toggle = toggle
    @prerequisites = prerequisites
    @channel_lost = channel_lost
    @parent_crumb = parent_crumb
  end

  def view_template(&block)
    render Components::ServerPage.new(server_configuration: @server_configuration, crumbs: trailing_crumbs) do
      if instant?
        page_content(&block)
      else
        save_form { page_content(&block) }
      end
    end
  end

  private

  def instant?
    @toggle&.fetch(:instant, false)
  end

  def locked?
    @toggle[:locked] || (instant? && @server_configuration.preview?)
  end

  def lock_reason
    return t("components.plugin_row.preview_locked") if instant? && @server_configuration.preview?

    @toggle[:reason]
  end

  def save_form
    form_with(
      url: @url,
      method: :patch,
      data: form_data
    ) do
      yield
      render Components::SaveBar.new(preview: @server_configuration.preview?)
    end
  end

  def page_content(&block)
    page_header
    body(&block)
  end

  def trailing_crumbs
    [@parent_crumb, {label: @header.title}].compact
  end

  def form_data
    {
      controller: "save-bar",
      action: "input->save-bar#check change->save-bar#check turbo:submit-end->save-bar#saved"
    }
  end

  def page_header
    if @header.banner
      div(class: "mb-6") { render @header.banner }
    else
      default_page_header
    end
  end

  def default_page_header
    div(class: "mb-6 flex items-start gap-4") do
      div(class: "mt-2 flex-none") { render Components::PluginTile.new(icon: @header.icon, size: :lg) }
      div(class: "flex-1") do
        div(class: "flex flex-wrap items-center gap-3") do
          h1(class: "font-display text-2xl font-bold tracking-tight") { @header.title }
          render Components::Badge.new(variant: :copper) { @header.badge } if @header.badge
          render @header.aside if @header.aside
        end
        p(class: "mt-1 text-sm text-text-secondary") { @header.description } if @header.description
      end
      enable_control if @toggle
    end
  end

  def enable_control
    div(class: "group/enable flex flex-none items-center gap-2.5 pt-1") do
      if locked?
        locked_enable_control
      else
        interactive_enable_control
      end
    end
  end

  def locked_enable_control
    span(class: "text-sm font-medium text-text-secondary") do
      @toggle[:enabled] ? t(".enabled") : t(".disabled")
    end
    render Components::Tooltip.new(text: lock_reason) do
      render Components::Toggle.new(
        name: @toggle[:field],
        checked: @toggle[:enabled],
        label: toggle_label,
        disabled: true
      )
    end
  end

  def interactive_enable_control
    span(class: "hidden text-sm font-medium text-text-secondary group-has-[:checked]/enable:inline") { t(".enabled") }
    span(class: "text-sm font-medium text-text-secondary group-has-[:checked]/enable:hidden") { t(".disabled") }
    render Components::Toggle.new(
      name: @toggle[:field],
      checked: @toggle[:enabled],
      label: toggle_label,
      **instant_options
    )
  end

  def instant_options
    return {} unless instant?

    {url: @url, submit_on_change: true}
  end

  def toggle_label
    @toggle[:label] || t(".enable", plugin: @header.title)
  end

  def body
    render @prerequisites if @prerequisites
    channel_lost_banner
    yield
  end

  def channel_lost_banner
    return unless @channel_lost

    div(class: "mb-5") do
      render Components::Callout.new(variant: :warning) { t(".channel_lost", plugin: @header.title) }
    end
  end
end
