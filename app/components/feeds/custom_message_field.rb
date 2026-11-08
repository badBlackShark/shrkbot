# frozen_string_literal: true

class Components::Feeds::CustomMessageField < Components::Feeds::TemplateField
  private

  def param
    :templates
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
    source.template_tokens
  end

  def preview_label
    t(".preview")
  end

  def card
    {
      eyebrow: ::Feeds::Steam::Announcement.eyebrow(@subscription.watch.name, @event_type, samples.value(:feed)),
      title: samples.value(:title),
      body: samples.value(:body),
      button: ::Feeds::Steam::Announcement::LINK_LABEL
    }
  end
end
