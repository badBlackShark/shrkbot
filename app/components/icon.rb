# frozen_string_literal: true

class Components::Icon < Components::Base
  def initialize(name, variant: :outline, **options)
    @name = name.to_s
    @variant = variant
    @options = options
    @options[:class] ||= "size-5"
  end

  def view_template
    svg = Heroicons::Icon.render(
      name: @name,
      variant: @variant,
      options: @options,
      path_options: {}
    )
    raw(safe(svg.to_s))
  end
end
