# frozen_string_literal: true

class Components::TomSelect < Components::Base
  Option = Data.define(:value, :label, :disabled, :color, :reason) do
    def self.for(value:, label:, disabled: false, color: nil, reason: nil)
      new(value: value, label: label, disabled: disabled, color: color, reason: reason)
    end

    def adornment
      {color: color, reason: reason}.compact
    end
  end

  def initialize(name:, options:, selected: nil, multiple: false, include_blank: false, controller_data: {})
    @name = name
    @options = options
    @selected = selected
    @multiple = multiple
    @include_blank = include_blank
    @controller_data = controller_data
  end

  def view_template
    select(name: @name, multiple: @multiple, autocomplete: "off", class: "w-full", data: {controller: "tom-select", **@controller_data}) do
      option(value: "") if @include_blank
      @options.each do |opt|
        option(**option_attrs(opt)) { opt.label }
      end
    end
  end

  private

  def option_attrs(opt)
    attrs = {value: opt.value}
    attrs[:selected] = true if selected?(opt)
    attrs[:disabled] = true if opt.disabled
    attrs[:data] = opt.adornment if opt.adornment.any?
    attrs
  end

  def selected?(opt)
    return false if @selected.blank?

    Array(@selected).map(&:to_s).include?(opt.value.to_s)
  end
end
