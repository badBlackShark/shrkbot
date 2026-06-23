class Components::TomSelect < Components::Base
  Option = Data.define(:value, :label, :disabled) do
    def self.for(value:, label:, disabled: false)
      new(value: value, label: label, disabled: disabled)
    end
  end

  def initialize(name:, options:, selected: nil, placeholder: nil, include_blank: false, dom_id: nil)
    @name = name
    @options = options
    @selected = selected
    @placeholder = placeholder
    @include_blank = include_blank
    @dom_id = dom_id
  end

  def view_template
    select(name: @name, id: @dom_id, autocomplete: "off", class: "w-full", data: data) do
      option(value: "") { @placeholder.to_s } if @include_blank
      @options.each do |opt|
        option(**option_attrs(opt)) { opt.label }
      end
    end
  end

  private

  def data
    attrs = {controller: "tom-select"}
    attrs[:tom_select_placeholder_value] = @placeholder if @placeholder
    attrs
  end

  def option_attrs(opt)
    attrs = {value: opt.value}
    attrs[:selected] = true if @selected.present? && opt.value.to_s == @selected.to_s
    attrs[:disabled] = true if opt.disabled
    attrs
  end
end
