# frozen_string_literal: true

class Components::DurationStepper < Components::NumberStepper
  UNIT_SECONDS = {seconds: 1, minutes: 60, hours: 3_600}.freeze
  UNIT_SEGMENT = "ts-segment relative flex border-l border-border-default text-text-secondary transition-colors " \
    "hover:bg-surface-sunken hover:text-text-primary #{TRAILING_CORNER}"

  def initialize(name:, value:, base:, min:, max:, default: nil, placeholder: nil)
    super(name:, value:, min:, max:, default:, placeholder:)
    @base = base
    @shown_unit = unit_for(value || placeholder)
  end

  private

  def shown_attributes
    {
      value: shown(@value),
      min: @min.ceildiv(factor),
      max: @max / factor,
      placeholder: shown(@placeholder)
    }
  end

  def controller_data
    data = super
    data[:number_stepper_default_unit_value] = units.fetch(unit_for(@default)) if resettable?
    data[:number_stepper_placeholder_value] = @placeholder if @placeholder
    data
  end

  def syncs?
    true
  end

  def reset_label
    unit = unit_for(@default)
    t("components.number_stepper.reset", value: t(".amount.#{unit}", count: @default / units.fetch(unit)))
  end

  def unit_segment
    div(class: UNIT_SEGMENT) do
      input(type: "hidden", name: @name, value: @value, data: {number_stepper_target: "field"})
      render Components::TomSelect.new(
        name: nil,
        options: unit_options,
        selected: factor,
        aria_label: t(".unit_label"),
        controller_data: {
          tom_select_fixed_value: true,
          number_stepper_target: "unit",
          action: "change->number-stepper#changeUnit"
        }
      )
      render Components::Icon.new("caret-down", class: "pointer-events-none absolute right-2.5 top-1/2 size-3.5 -translate-y-1/2")
    end
  end

  def unit_options
    units.map do |key, size|
      Components::TomSelect::Option.for(value: size, label: t(".units.#{key}"))
    end
  end

  def units
    base_seconds = UNIT_SECONDS.fetch(@base)
    UNIT_SECONDS.filter_map { |key, seconds| [key, seconds / base_seconds] if seconds >= base_seconds }.to_h
  end

  def unit_for(total)
    return @base if total.to_i.zero?

    units.keys.rfind { |key| (total % units.fetch(key)).zero? }
  end

  def factor
    units.fetch(@shown_unit)
  end

  def shown(total)
    return nil if total.nil?

    amount = Rational(total, factor)
    (amount.denominator == 1) ? amount.to_i : amount.to_f.round(2)
  end
end
