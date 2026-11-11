# frozen_string_literal: true

class Components::Feeds::NotificationField < Components::Feeds::TemplateField
  private

  def param
    :notification
  end

  def label_row
    div(class: "flex items-center justify-between gap-3") do
      label(for: field_id, class: "text-sm font-semibold") { t(".label") }
      render Components::ResetButton.new(
        label: t(".reset"),
        data: {action: "feed-preview#reset"}
      )
    end
  end

  def value
    @event&.notification_template || source.default_notification(@event_type)
  end

  def textarea_data
    super.merge(fallback: source.default_notification(@event_type))
  end

  def token_names
    source.notification_tokens & source.tokens_for(@event_type)
  end

  def preview_label
    t(".preview")
  end
end
