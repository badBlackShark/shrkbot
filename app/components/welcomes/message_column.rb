# frozen_string_literal: true

class Components::Welcomes::MessageColumn < Components::Base
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
    end
  end

  def heading
    div(class: "flex min-h-8 items-center justify-between gap-3") do
      label(for: field_id, class: "block text-sm font-semibold") { t(".#{@kind}_message.label") }
      reset_button
    end
  end

  def reset_button
    render Components::ResetSlot.new(
      label: t(".reset_to_default"),
      hidden: message == default_message,
      slot_data: {welcome_preview_target: "#{@kind}Reset"},
      data: {action: "welcome-preview#reset", welcome_preview_kind_param: @kind}
    )
  end

  def field
    render Components::TemplateTextarea.new(
      name: "welcomes[#{@kind}_message]",
      id: field_id,
      value: message,
      rows: 4,
      mono: false,
      placeholder: t(".empty"),
      data: {
        welcome_preview_target: "#{@kind}Message",
        action: "input->welcome-preview#render",
        default: default_message
      }
    )
  end

  def message
    @settings.public_send(:"#{@kind}_message")
  end

  def default_message
    column_default(::Welcomes::Settings, "#{@kind}_message")
  end

  def field_id
    "welcomes_#{@kind}_message"
  end
end
