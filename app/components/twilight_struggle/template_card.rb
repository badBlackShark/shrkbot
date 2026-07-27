# frozen_string_literal: true

class Components::TwilightStruggle::TemplateCard < Components::Base
  FIELD = "w-full resize-none rounded-control border-[1.5px] border-border-strong bg-surface-card px-3 py-2 " \
    "font-mono text-sm text-text-primary placeholder:text-text-secondary focus:border-accent focus:outline-none " \
    "focus:ring-3 focus:ring-[var(--focus-ring)]"

  RESET = "inline-flex size-8 items-center justify-center rounded-control border border-border-default " \
    "text-text-secondary transition-colors hover:bg-surface-sunken focus:outline-none " \
    "focus-visible:ring-2 focus-visible:ring-[var(--focus-ring)]"

  def initialize(kind:, value:, placeholder:, channel:, inherits_from_parent: false)
    @kind = kind
    @value = value
    @placeholder = placeholder
    @channel = channel
    @inherits_from_parent = inherits_from_parent
  end

  def view_template
    render Components::Card.new do
      heading
      field
      preview
    end
  end

  private

  def heading
    div(class: "mb-2 flex items-start justify-between gap-3") do
      div do
        label(class: "block text-sm font-semibold") { t(".#{@kind}.label") }
        p(class: "mt-0.5 text-sm text-text-secondary") { t(".#{@kind}.help") }
      end
      reset_button
    end
  end

  def reset_button
    render Components::Tooltip.new(text: reset_label) do
      button(
        type: "button",
        aria_label: reset_label,
        class: RESET,
        data: {action: "twilight-struggle-preview#reset", twilight_struggle_preview_kind_param: @kind}
      ) do
        render Components::Icon.new("arrow-counter-clockwise", class: "size-4")
      end
    end
  end

  def reset_label
    @inherits_from_parent ? t(".reset_to_parent") : t(".reset_to_default")
  end

  def field
    textarea(
      name: "destination[template_#{@kind}]",
      rows: 2,
      class: FIELD,
      placeholder: @placeholder,
      data: {twilight_struggle_preview_target: "#{@kind}Template"}
    ) { @value }
  end

  def preview
    render Components::DiscordMessagePreview.new(
      label: t(".preview"),
      channel: @channel,
      messages: [{body_data: {twilight_struggle_preview_target: "#{@kind}Output", empty_hint: t(".empty")}}]
    )
  end
end
