# frozen_string_literal: true

class Components::TwilightStruggle::SettingCardBase < Components::Base
  HELP = "mt-0.5 text-sm text-text-secondary"

  def initialize(destination:, inherited:)
    @destination = destination
    @inherited = inherited
  end

  def view_template
    render Components::Card.new(class: "group/setting") do
      p(class: "text-sm font-semibold") { t(".label") }
      help
      div(class: "mt-3") { control }
      inherit_note
    end
  end

  private

  def help
    p(class: HELP) { t(".help") }
  end

  def parent
    @inherited.inherited_from
  end

  def source
    @inherited.source_of(attribute)
  end

  def inherit_note
    return unless parent

    render Components::TwilightStruggle::InheritNote.new { inherit_note_text }
  end

  def inherit_note_text
    return t(".inherits_default", **inherited_values) unless source

    t(".inherits_from", parent: source.name, **inherited_values)
  end
end
