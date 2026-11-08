# frozen_string_literal: true

class Components::Feeds::NotificationField < Components::Feeds::TemplateField
  private

  def param
    :notifications
  end

  def label_row
    div(class: "flex flex-col gap-1") do
      label(for: field_id, class: "text-sm font-semibold") { t(".label") }
      p(class: "text-sm text-text-secondary") { t(".help") }
    end
  end

  def value
    @event&.notification_template || source.default_notification(@event_type)
  end

  def textarea_data
    super.merge(fallback: source.default_notification(@event_type))
  end

  def token_names
    source.notification_tokens
  end

  def preview_label
    t(".preview")
  end
end
