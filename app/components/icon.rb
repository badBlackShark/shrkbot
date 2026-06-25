# frozen_string_literal: true

class Components::Icon < Components::Base
  def initialize(name, weight: :regular, **options)
    @name = name.to_s
    @weight = weight
    @options = options
    @options[:class] ||= "size-5"
  end

  def view_template
    raw(safe(PhosphorIcons::Icon.new(@name, style: @weight, **@options).to_svg))
  end
end
