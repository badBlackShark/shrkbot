# frozen_string_literal: true

class Components::Feeds::LookupTextField < Components::Base
  FIELD = "w-full rounded-control border-[1.5px] border-border-strong bg-surface-card px-3 py-2 font-mono text-sm " \
    "text-text-primary placeholder:text-text-secondary focus:border-accent focus:outline-none " \
    "focus:ring-3 focus:ring-[var(--focus-ring)] aria-invalid:border-danger"

  def initialize(name:, value:, error_id:, server_configuration:)
    @name = name
    @value = value
    @error_id = error_id
  end

  def view_template
    input(
      type: "text",
      name: @name,
      value: @value,
      class: FIELD,
      autofocus: true,
      autocomplete: "off",
      aria_invalid: problem?.to_s,
      aria_describedby: @error_id
    )
  end

  private

  def problem?
    !@error_id.nil?
  end
end
