# frozen_string_literal: true

class Components::TwilightStruggle::PostDelayCard < Components::TwilightStruggle::SettingCardBase
  private

  def control
    render Components::NumberStepper.new(
      name: "destination[post_delay_minutes]",
      value: own_minutes,
      min: 0,
      max: ::TwilightStruggle::Destination::MAX_POST_DELAY.in_minutes.to_i,
      unit: t(".unit"),
      placeholder: inherited_minutes
    )
  end

  def attribute
    :post_delay_seconds
  end

  def inherited_values
    {count: inherited_minutes}
  end

  def own_minutes
    return nil if @destination.post_delay_seconds.nil?

    @destination.post_delay_seconds / 60
  end

  def inherited_minutes
    @inherited.post_delay.in_minutes.to_i
  end
end
