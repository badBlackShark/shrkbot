# frozen_string_literal: true

class Components::Feeds::CustomMessageField < Components::Feeds::TemplateField
  private

  def param
    :template
  end

  def label_row
    label(for: field_id, class: "text-sm font-semibold") { t(".label") }
  end

  def value
    @event&.template
  end

  def placeholder
    t(".placeholder")
  end

  def token_names
    source.template_tokens & source.tokens_for(@event_type)
  end

  def preview_label
    t(".preview")
  end

  def card
    samples.card
  end
end
