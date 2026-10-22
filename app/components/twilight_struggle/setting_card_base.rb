# frozen_string_literal: true

class Components::TwilightStruggle::SettingCardBase < Components::Base
  def initialize(destination:, inherited:)
    @destination = destination
    @inherited = inherited
  end

  def view_template
    render Components::Card.new do
      p(class: "text-sm font-semibold") { t(".label") }
      p(class: "mb-3 mt-0.5 text-sm text-text-secondary") { t(".help") }
      control
      inherit_note
    end
  end

  private

  def parent
    @inherited.inherited_from
  end

  def source
    @inherited.source_of(attribute)
  end

  def inherit_note
    return unless parent

    p(class: "mt-2 text-xs text-text-secondary") { inherit_note_text }
  end

  def inherit_note_text
    return t(".inherits_default", **inherited_values) unless source

    t(".inherits_from", parent: source.name, **inherited_values)
  end
end
