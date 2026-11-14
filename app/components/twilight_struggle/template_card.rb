# frozen_string_literal: true

class Components::TwilightStruggle::TemplateCard < Components::Base
  def initialize(kind:, value:, inherited:, channel:, inherits_from_parent: false)
    @kind = kind
    @value = value
    @inherited = inherited
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
    render Components::ResetSlot.new(
      label: reset_label,
      hidden: @value == @inherited,
      slot_data: {twilight_struggle_preview_target: "#{@kind}Reset"},
      data: {action: "twilight-struggle-preview#reset", twilight_struggle_preview_kind_param: @kind}
    )
  end

  def reset_label
    @inherits_from_parent ? t(".reset_to_parent") : t(".reset_to_default")
  end

  def field
    render Components::TemplateTextarea.new(
      name: "destination[template_#{@kind}]",
      value: @value,
      placeholder: t(".empty"),
      data: {twilight_struggle_preview_target: "#{@kind}Template", default: @inherited}
    )
  end

  def preview
    render Components::DiscordMessagePreview.new(
      label: t(".preview"),
      channel: @channel,
      messages: [{body_data: {twilight_struggle_preview_target: "#{@kind}Output", empty_hint: t(".empty")}}]
    )
  end
end
