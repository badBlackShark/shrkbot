# frozen_string_literal: true

class Components::TwilightStruggle::SettingCardBase < Components::Base
  def initialize(destination:, inherited:)
    @destination = destination
    @inherited = inherited
  end

  def view_template
    render Components::Card.new(class: "group/setting") do
      p(class: "text-sm font-semibold") { t(".label") }
      div(class: "mt-3") { control }
      help
      inherit_note
    end
  end

  private

  def help
    render Components::FieldHelp.new { t(".help") }
  end

  def parent
    @inherited.inherited_from
  end

  def source
    @inherited.source_of(attribute)
  end

  def inherit_note
    return unless parent

    render Components::TwilightStruggle::InheritNote.new(visible_when: inherit_note_visible_when) { inherit_note_text }
  end

  def inherit_note_text
    return t(".inherits_default", **inherited_values) unless source

    t(".inherits_from", parent: source.name, **inherited_values)
  end
end
