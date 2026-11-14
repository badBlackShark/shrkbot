# frozen_string_literal: true

class Components::Welcomes::MessageColumn < Components::Base
  FIELD = "w-full resize-none rounded-control border-[1.5px] border-border-strong bg-surface-card px-3 py-2 " \
    "text-sm text-text-primary placeholder:text-text-secondary focus:border-accent focus:outline-none " \
    "focus:ring-3 focus:ring-[var(--focus-ring)]"
  SCOPE = "components.welcomes.config_form"

  def initialize(kind:, settings:)
    @kind = kind
    @settings = settings
  end

  def view_template(&)
    div(class: "flex min-w-0 flex-1 flex-col gap-4 px-5") do
      message_group
      yield
    end
  end

  private

  def message_group
    div(class: "flex flex-col gap-2") do
      heading
      field
      info_line
    end
  end

  def heading
    div(class: "flex min-h-8 items-center justify-between gap-3") do
      div do
        label(for: field_id, class: "block text-sm font-semibold") { t("#{SCOPE}.#{@kind}_message.label") }
        p(class: "mt-0.5 text-sm text-text-secondary") { t("#{SCOPE}.#{@kind}_message.help") }
      end
      reset_button
    end
  end

  def reset_button
    span(
      class: "flex",
      hidden: message == default_message,
      data: {welcome_preview_target: "#{@kind}Reset"}
    ) do
      render Components::ResetButton.new(
        label: t("components.welcomes.config_form.reset_to_default"),
        data: {action: "welcome-preview#reset", welcome_preview_kind_param: @kind}
      )
    end
  end

  def field
    textarea(
      name: "welcomes[#{@kind}_message]",
      id: field_id,
      rows: 4,
      class: FIELD,
      placeholder: t("components.welcomes.config_form.empty"),
      data: {
        welcome_preview_target: "#{@kind}Message",
        action: "input->welcome-preview#render",
        default: default_message
      }
    ) { message }
  end

  def info_line
    p(class: "flex items-start gap-1 text-xs text-text-secondary") do
      render Components::Icon.new("info", class: "mt-0.5 size-3 flex-none text-accent")
      span do
        code(class: "font-mono") { "{user}" }
        whitespace
        plain t("#{SCOPE}.#{@kind}_message.info")
      end
    end
  end

  def message
    @settings.public_send(:"#{@kind}_message")
  end

  def default_message
    ::Welcomes::Settings.column_defaults.fetch("#{@kind}_message")
  end

  def field_id
    "welcomes_#{@kind}_message"
  end
end
