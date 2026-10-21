# frozen_string_literal: true

class Components::TwilightStruggle::PostDelayCard < Components::Base
  def initialize(destination:, inherited:)
    @destination = destination
    @inherited = inherited
  end

  def view_template
    render Components::Card.new do
      p(class: "text-sm font-semibold") { t(".label") }
      p(class: "mb-3 mt-0.5 text-sm text-text-secondary") { t(".help") }
      render Components::NumberStepper.new(
        name: "destination[post_delay_minutes]",
        value: own_minutes,
        min: 0,
        max: ::TwilightStruggle::Destination::MAX_POST_DELAY.in_minutes.to_i,
        unit: t(".unit"),
        placeholder: inherited_minutes
      )
      inherit_note
    end
  end

  private

  def parent
    @inherited.inherited_from
  end

  def own_minutes
    return nil if @destination.post_delay_seconds.nil?

    @destination.post_delay_seconds / 60
  end

  def inherited_minutes
    @inherited.post_delay.in_minutes.to_i
  end

  def inherit_note
    return unless parent

    p(class: "mt-2 text-xs text-text-secondary") do
      t(".inherits_from", parent: parent.name, count: inherited_minutes)
    end
  end
end
