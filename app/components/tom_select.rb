# frozen_string_literal: true

class Components::TomSelect < Components::Base
  Option = Data.define(:value, :label, :disabled, :color, :reason) do
    def self.for(value:, label:, disabled: false, color: nil, reason: nil)
      new(value: value, label: label, disabled: disabled, color: color, reason: reason)
    end
  end

  def initialize(
    name:,
    options:,
    selected: nil,
    placeholder: nil,
    include_blank: false,
    prefix: nil,
    multiple: false,
    color_dots: false,
    dom_id: nil
  )
    @name = name
    @options = options
    @selected = selected
    @placeholder = placeholder
    @include_blank = include_blank
    @prefix = prefix
    @multiple = multiple
    @color_dots = color_dots
    @dom_id = dom_id
  end

  def view_template
    select(name: @name, id: @dom_id, multiple: @multiple, autocomplete: "off", class: "w-full", data: data) do
      option(value: "") if @include_blank
      @options.each do |opt|
        option(**option_attrs(opt)) { opt.label }
      end
    end
  end

  private

  def data
    attrs = {controller: "tom-select"}
    attrs[:tom_select_placeholder_value] = @placeholder if @placeholder
    attrs[:tom_select_prefix_value] = @prefix if @prefix
    attrs[:tom_select_color_dots_value] = true if @color_dots
    attrs
  end

  def option_attrs(opt)
    attrs = {value: opt.value}
    attrs[:selected] = true if selected?(opt)
    attrs[:disabled] = true if opt.disabled
    attrs[:data] = {data: adornment(opt)} if @color_dots
    attrs
  end

  def adornment(opt)
    {color: opt.color, reason: opt.reason}.compact.to_json
  end

  def selected?(opt)
    return false if @selected.blank?

    Array(@selected).map(&:to_s).include?(opt.value.to_s)
  end
end
