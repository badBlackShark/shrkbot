# frozen_string_literal: true

class Components::Welcomes::ConfigForm < Components::Base
  FIELD = "w-full rounded-control border border-border-default bg-surface-card px-3 py-2 text-sm text-text-primary " \
    "placeholder:text-text-secondary focus:border-accent focus:outline-none focus:ring-3 focus:ring-[var(--focus-ring)]"

  def initialize(server_configuration:, enable_error: nil)
    @config = server_configuration
    @settings = server_configuration.welcome_settings
    @enable_error = enable_error
  end

  def view_template
    div(id: "welcomes-config", class: "flex flex-col gap-5", data: {controller: "welcome-preview"}) do
      enable_error_callout
      channel_card
      messages_card
    end
  end

  private

  def enable_error_callout
    return unless @enable_error

    render Components::Callout.new(variant: :danger) { @enable_error }
  end

  def channel_card
    render Components::Card.new do
      label(class: "block text-sm font-semibold") { t(".channel.label") }
      p(class: "mb-2 mt-0.5 text-sm text-text-secondary") { t(".channel.help") }
      if channels.empty?
        p(class: "text-sm text-text-secondary") { t(".channel.none") }
      else
        render Components::TomSelect.new(
          name: "welcomes[channel_id]",
          options: channels,
          selected: @settings.channel_id,
          placeholder: t(".channel.placeholder"),
          include_blank: true
        )
      end
    end
  end

  def messages_card
    render Components::Card.new do
      message_field(:join_message, @settings.join_message)
      div(class: "my-5 border-t border-border-default")
      message_field(:leave_message, @settings.leave_message)
      placeholder_help
      preview
    end
  end

  def message_field(name, value)
    div do
      label(class: "block text-sm font-semibold") { t(".#{name}.label") }
      p(class: "mb-2 mt-0.5 text-sm text-text-secondary") { t(".#{name}.help") }
      textarea(
        name: "welcomes[#{name}]",
        rows: 3,
        class: FIELD,
        placeholder: t(".#{name}.placeholder"),
        data: {welcome_preview_target: camel(name), action: "input->welcome-preview#render"}
      ) { value }
    end
  end

  def placeholder_help
    div(class: "mt-4 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-text-secondary") do
      span { t(".placeholders.intro") }
      placeholder_chip("{user}", t(".placeholders.user"))
      placeholder_chip("{membercount}", t(".placeholders.membercount"))
    end
  end

  def placeholder_chip(token, description)
    span(class: "inline-flex items-center gap-1.5") do
      code(class: "rounded bg-surface-sunken px-1.5 py-0.5 font-mono text-accent-soft-fg") { token }
      span { description }
    end
  end

  def preview
    div(class: "mt-5") do
      p(class: "mb-2 text-[11px] font-semibold uppercase tracking-widest text-text-secondary") { t(".preview.label") }
      div(class: "flex flex-col gap-3 rounded-md bg-surface-sunken p-4") do
        preview_row(:join)
        preview_row(:leave)
      end
    end
  end

  def preview_row(kind)
    div(class: "flex items-start gap-3") do
      span(class: "flex size-9 flex-none items-center justify-center rounded-full bg-accent-fill text-xs font-bold text-white") { "n" }
      div(class: "min-w-0") do
        p(class: "text-xs font-semibold text-text-secondary") { t(".preview.#{kind}") }
        p(
          class: "text-sm text-text-primary",
          data: {welcome_preview_target: "#{kind}Output", empty_hint: t(".preview.empty")}
        )
      end
    end
  end

  def channels
    @channels ||= @config.server_channels.text.map do |channel|
      Components::TomSelect::Option.for(value: channel.discord_id, label: "# #{channel.name}")
    end
  end

  def camel(name)
    name.to_s.camelize(:lower)
  end
end
