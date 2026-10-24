# frozen_string_literal: true

class Components::TemplateTextarea < Components::Base
  FIELD = "w-full resize-none rounded-control border-[1.5px] border-border-strong bg-surface-card px-3 py-2 " \
    "font-mono text-sm text-text-primary placeholder:text-text-secondary focus:border-accent focus:outline-none " \
    "focus:ring-3 focus:ring-[var(--focus-ring)]"

  def initialize(name:, value:, placeholder:, rows: 2, data: {}, id: nil)
    @name = name
    @value = value
    @placeholder = placeholder
    @rows = rows
    @data = data
    @id = id
  end

  def view_template
    textarea(
      name: @name,
      id: @id,
      rows: @rows,
      class: FIELD,
      placeholder: @placeholder,
      data: @data
    ) { @value }
  end
end
