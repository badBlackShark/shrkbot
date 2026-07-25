# frozen_string_literal: true

class Components::TwilightStruggle::TemplateCard < Components::Base
  FIELD = "w-full resize-none rounded-control border-[1.5px] border-border-strong bg-surface-card px-3 py-2 " \
    "font-mono text-sm text-text-primary placeholder:text-text-secondary focus:border-accent focus:outline-none " \
    "focus:ring-3 focus:ring-[var(--focus-ring)]"

  def initialize(kind:, value:, placeholder:, channel:)
    @kind = kind
    @value = value
    @placeholder = placeholder
    @channel = channel
  end

  def view_template
    render Components::Card.new do
      label(class: "block text-sm font-semibold") { t(".#{@kind}.label") }
      p(class: "mb-2 mt-0.5 text-sm text-text-secondary") { t(".#{@kind}.help") }
      field
      p(class: "mb-3 mt-1.5 text-xs text-text-secondary") { t(".inherit") }
      preview
    end
  end

  private

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
