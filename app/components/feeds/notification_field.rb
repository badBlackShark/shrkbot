# frozen_string_literal: true

class Components::Feeds::NotificationField < Components::Feeds::TemplateField
  private

  def param
    :notification
  end

  def label_row
    div(class: "flex min-h-8 items-center justify-between gap-3") do
      label(for: field_id, class: "text-sm font-semibold") { t(".label") }
      render Components::ResetSlot.new(
        label: t(".reset"),
        hidden: value == default,
        slot_data: {feed_preview_target: "reset"},
        data: {action: "feed-preview#reset"}
      )
    end
  end

  def value
    @event&.notification_template || default
  end

  def default
    source.default_notification(@event_type)
  end

  def textarea_data
    super.merge(fallback: default)
  end

  def preview_label
    t(".preview")
  end
end
